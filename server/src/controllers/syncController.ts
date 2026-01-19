
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/authMiddleware';
import { notifyClassManagers } from '../utils/notificationUtils';

const prisma = new PrismaClient();

import { getUserManagedClassIds, isClassManager } from '../utils/authUtils';

export const syncChanges = async (req: AuthRequest, res: Response) => {
    if (req.method === 'POST') {
        return handlePush(req, res);
    } else if (req.method === 'GET') {
        return handlePull(req, res);
    } else {
        return res.sendStatus(405);
    }
};

const handlePush = async (req: AuthRequest, res: Response) => {
    const { changes } = req.body;
    console.log(`SyncController: Received push request with ${changes?.length || 0} changes`);
    if (!Array.isArray(changes)) return res.status(400).json({ message: 'Invalid format' });

    // Validate User Permissions
    const userId = req.user?.userId;
    const userRole = req.user?.role;

    if (!userId) return res.sendStatus(401);

    // Sort changes by dependency order: CLASS -> USER/STUDENT -> ATTENDANCE/NOTE
    // ATTENDANCE_SESSION should be processed before ATTENDANCE records that reference it
    const priority = {
        'CLASS': 1,
        'USER': 2,
        'STUDENT': 3,
        'ATTENDANCE_SESSION': 4,
        'ATTENDANCE': 5,
        'NOTE': 5
    };

    changes.sort((a: any, b: any) => {
        const pA = priority[a.entityType as keyof typeof priority] || 99;
        const pB = priority[b.entityType as keyof typeof priority] || 99;
        return pA - pB;
    });

    const processedUuids: string[] = [];
    const failedUuids: { uuid: string; error: string }[] = [];

    // Group changes by priority
    const changesByPriority: { [key: number]: any[] } = {};
    for (const change of changes) {
        const p = priority[change.entityType as keyof typeof priority] || 99;
        if (!changesByPriority[p]) {
            changesByPriority[p] = [];
        }
        changesByPriority[p].push(change);
    }

    // Process batches by priority
    const sortedPriorities = Object.keys(changesByPriority).map(Number).sort((a, b) => a - b);

    for (const p of sortedPriorities) {
        const batch = changesByPriority[p];
        const promises: any[] = [];
        const batchUuids = batch.map(c => c.uuid);

        for (const change of batch) {
            const { uuid, entityType, entityId, operation, payload } = change;

            // --- SECURITY CHECK ---
            if (userRole !== 'ADMIN') {
                const sanitizedPayload = sanitizePayload(payload);
                let isAuthorized = false;

                try {
                    if (entityType === 'CLASS' || entityType === 'USER' || entityType === 'CLASS_MANAGER') {
                        // Regular users generally shouldn't be pushing CLASS/USER changes
                        // Exception: Maybe updating their own user profile?
                        // For now, deny unless logic specifically allows (like class creation if we allowed it, but usually admin only)
                        failedUuids.push({ uuid, error: 'Forbidden: Insufficient permissions for this entity type' });
                        continue;
                    } else if (entityType === 'student' || entityType === 'STUDENT') { // Normalize casing check
                        if (sanitizedPayload.classId) {
                            isAuthorized = await isClassManager(userId, sanitizedPayload.classId);
                        }
                    } else if (entityType === 'attendance_session' || entityType === 'ATTENDANCE_SESSION') {
                        if (sanitizedPayload.classId) {
                            isAuthorized = await isClassManager(userId, sanitizedPayload.classId);
                        }
                    } else if (entityType === 'note' || entityType === 'NOTE') {
                        if (sanitizedPayload.studentId) {
                            const student = await prisma.student.findUnique({
                                where: { id: sanitizedPayload.studentId },
                                select: { classId: true }
                            });
                            if (student?.classId) {
                                isAuthorized = await isClassManager(userId, student.classId);
                            }
                        }
                    } else if (entityType === 'attendance' || entityType === 'ATTENDANCE' || entityType === 'attendance_record') { // Normalize
                        // For attendance, we need to check the session -> class
                        if (sanitizedPayload.sessionId) {
                            const session = await prisma.attendanceSession.findUnique({
                                where: { id: sanitizedPayload.sessionId },
                                select: { classId: true }
                            });
                            if (session?.classId) {
                                isAuthorized = await isClassManager(userId, session.classId);
                            }
                        }
                    }

                    if (!isAuthorized) {
                        console.warn(`SyncController: User ${userId} blocked from ${operation} on ${entityType}`);
                        failedUuids.push({ uuid, error: 'Forbidden: You do not manage this class' });
                        continue;
                    }

                } catch (err) {
                    console.error('Security check error:', err);
                    failedUuids.push({ uuid, error: 'Authorization check failed' });
                    continue;
                }
            }


            const modelName = mapEntityToModel(entityType);
            if (!modelName) {
                console.warn(`Unknown entity type: ${entityType}`);
                failedUuids.push({ uuid, error: `Unknown entity type: ${entityType}` });
                continue; // Skip this change
            }
            const dbModel = (prisma as any)[modelName];

            if (operation === 'VIRTUAL_DELETE' || operation === 'DELETE') {
                const deleteData: any = {
                    isDeleted: true,
                    deletedAt: payload.deletedAt ? new Date(payload.deletedAt) : new Date(),
                    updatedAt: new Date()
                };
                promises.push(dbModel.updateMany({
                    where: { id: entityId },
                    data: deleteData
                }));
            } else {
                const sanitizedPayload = sanitizePayload(payload);
                promises.push(dbModel.upsert({
                    where: { id: entityId },
                    create: { ...sanitizedPayload, id: entityId },
                    update: { ...sanitizedPayload },
                }));
            }
        }

        if (promises.length === 0) continue;

        try {
            await prisma.$transaction(promises);
            processedUuids.push(...batchUuids);

            // --- Notification Triggers for successful batch ---
            // Fire and forget to not block sync response
            (async () => {
                try {
                    // @ts-ignore
                    const authorId = req.user?.userId;

                    // Collect IDs for bulk fetching
                    const studentIds = new Set<string>();
                    const classIds = new Set<string>();

                    for (const change of batch) {
                        const { entityType, operation, payload } = change;
                        const sanitizedPayload = sanitizePayload(payload);

                        if (entityType === 'NOTE' && operation === 'CREATE' && sanitizedPayload.studentId) {
                            studentIds.add(sanitizedPayload.studentId);
                        } else if (entityType === 'ATTENDANCE_SESSION' && operation === 'CREATE' && sanitizedPayload.classId) {
                            classIds.add(sanitizedPayload.classId);
                        }
                    }

                    // Bulk fetch related data
                    const [students, classes, author] = await Promise.all([
                        studentIds.size > 0 ? prisma.student.findMany({ where: { id: { in: Array.from(studentIds) } } }) : [],
                        classIds.size > 0 ? prisma.class.findMany({ where: { id: { in: Array.from(classIds) } } }) : [],
                        authorId ? prisma.user.findUnique({ where: { id: authorId } }) : Promise.resolve(null)
                    ]);

                    const studentMap = new Map(students.map((s: any) => [s.id, s]));
                    const classMap = new Map(classes.map((c: any) => [c.id, c]));
                    const authorName = author?.name || 'A servant';

                    for (const change of batch) {
                        const { entityType, operation, payload } = change;
                        const sanitizedPayload = sanitizePayload(payload);

                        if (entityType === 'NOTE' && operation === 'CREATE') {
                            const student: any = studentMap.get(sanitizedPayload.studentId);
                            if (student && student.classId && authorId) {
                                await notifyClassManagers(
                                    student.classId,
                                    'noteAdded',
                                    '📝 New Note',
                                    `${authorName} added a note for ${student.name}`,
                                    { studentId: student.id },
                                    authorId
                                );
                            }
                        } else if (entityType === 'ATTENDANCE_SESSION' && operation === 'CREATE') {
                            if (sanitizedPayload.classId && authorId) {
                                const cls: any = classMap.get(sanitizedPayload.classId);
                                await notifyClassManagers(
                                    sanitizedPayload.classId,
                                    'attendanceRecorded',
                                    '📊 Attendance Recorded',
                                    `${authorName} recorded attendance for ${cls?.name || 'class'}`,
                                    { classId: sanitizedPayload.classId },
                                    authorId
                                );
                            }
                        }
                    }
                } catch (err) {
                    console.error('Notification trigger error:', err);
                }
            })();

        } catch (e: any) {
            console.error(`Sync transaction error for priority ${p}:`, e);
            batch.forEach(change => {
                failedUuids.push({ uuid: change.uuid, error: e.message || String(e) });
            });
        }
    }

    // Emit update event to all clients
    const io = req.app.get('io');
    if (io) {
        io.emit('sync_update');
    }

    res.json({ success: true, processedUuids, failedUuids });
};

const sanitizePayload = (payload: any) => {
    const newPayload = { ...payload };
    for (const key in newPayload) {
        let value = newPayload[key];
        if (typeof value === 'string') {
            if (key.endsWith('At') || key === 'date' || key === 'birthdate') {
                if (/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}/.test(value)) {
                    value = value.replace(/(\.\d{3})\d+/, '$1');
                }
                const date = new Date(value);
                if (!isNaN(date.getTime())) {
                    newPayload[key] = date;
                }
            }
        }
    }
    return newPayload;
};

const handlePull = async (req: AuthRequest, res: Response) => {
    const since = req.query.since as string;
    const sinceDate = since ? new Date(since) : new Date(0);
    const serverTimestamp = new Date().toISOString();

    const userId = req.user?.userId;
    const role = req.user?.role;
    let managedClassIds: string[] = [];

    if (role !== 'ADMIN' && userId) {
        managedClassIds = await getUserManagedClassIds(userId);
    }

    // Helper for where clauses
    const classFilter = role === 'ADMIN' ? {} : { id: { in: managedClassIds } };
    const studentFilter = role === 'ADMIN' ? {} : { classId: { in: managedClassIds } };
    const sessionFilter = role === 'ADMIN' ? {} : { classId: { in: managedClassIds } };
    // Attendance/Notes are fetched via join-like logic or simply fetching all if related to managed classes.
    // Since Prisma findMany doesn't easily do deep joins for where clauses without include,
    // we can fetch sessions first for attendance, or filter post-query (less efficient but safer for complex restrictions).
    // Better: use where condition relations if possible.

    // 1. Students
    const students = await prisma.student.findMany({
        where: {
            updatedAt: { gt: sinceDate },
            ...studentFilter
        },
    });

    // 2. Attendance Sessions
    const attendanceSessions = await prisma.attendanceSession.findMany({
        where: {
            updatedAt: { gt: sinceDate },
            ...sessionFilter
        },
    });

    // 3. Classes (with managers for managerNames de-normalization)
    const classesRaw = await prisma.class.findMany({
        where: {
            updatedAt: { gt: sinceDate },
            ...classFilter
        },
        include: {
            managers: {
                include: {
                    user: {
                        select: { name: true }
                    }
                }
            }
        }
    });

    // De-normalize managerNames for sync
    const classes = classesRaw.map(cls => {
        const { managers, ...classData } = cls;
        return {
            ...classData,
            managerNames: managers
                .map((m: any) => m.user?.name)
                .filter((n: any) => n)
                .join(', ')
        };
    });

    // 4. Attendance Records
    // For non-admins, valid records are those belonging to sessions in managed classes
    const attendanceWhere: any = { updatedAt: { gt: sinceDate } };
    if (role !== 'ADMIN') {
        attendanceWhere.session = { classId: { in: managedClassIds } };
    }
    const attendance = await prisma.attendanceRecord.findMany({ where: attendanceWhere });


    // 5. Notes
    // For non-admins, notes regarding students in managed classes
    const noteWhere: any = { updatedAt: { gt: sinceDate } };
    if (role !== 'ADMIN') {
        noteWhere.student = { classId: { in: managedClassIds } };
    }
    const notes = await prisma.note.findMany({ where: noteWhere });

    // 6. Users
    // Admins see all users. Managers see themselves + other managers of their classes?
    // or just themselves. "Ghost data" issue suggests they see too many.
    // Let's restrict to just themselves and maybe managers of shared classes if needed for UI.
    // Safe bet: Admins see all. Servants see only themselves and maybe admins/managers relevant to their context.
    // For now, let's restrict Servants to only users involved in their classes + themselves using a simpler logic if possible.
    // But 'users' table is mainly for login. The 'class_managers' table links them.
    // Let's keep it simple: Admins fetch all. Non-admins fetches themselves + users who are managers of their managed classes.

    let userWhere: any = { updatedAt: { gt: sinceDate } };
    if (role !== 'ADMIN') {
        // Find users who manage the same classes
        const managersOfMyClasses = await prisma.classManager.findMany({
            where: { classId: { in: managedClassIds } },
            select: { userId: true }
        });
        const allowedUserIds = managersOfMyClasses.map(m => m.userId);
        if (userId) allowedUserIds.push(userId); // Ensure self is included

        userWhere.id = { in: allowedUserIds };
    }

    const users = await prisma.user.findMany({
        where: userWhere,
        select: {
            id: true,
            name: true,
            email: true,
            role: true,
            classId: true,
            whatsappTemplate: true,
            isActive: true,
            isEnabled: true,
            activationDenied: true,
            createdAt: true,
            updatedAt: true,
            deletedAt: true,
            isDeleted: true,
        }
    });

    // 7. Class Managers - STOP SYNCING THIS TABLE
    // const classManagers = await prisma.classManager.findMany({ where: cmWhere });

    res.json({
        serverTimestamp,
        changes: {
            students,
            attendance_sessions: attendanceSessions,
            attendance,
            notes,
            classes,
            users,
        },
    });
};


const mapEntityToModel = (type: string): string | null => {
    switch (type) {
        case 'STUDENT': return 'student';
        case 'ATTENDANCE_SESSION': return 'attendanceSession';
        case 'ATTENDANCE': return 'attendanceRecord';
        case 'NOTE': return 'note';
        case 'CLASS': return 'class';
        case 'USER': return 'user';
        default: return null;
    }
};
