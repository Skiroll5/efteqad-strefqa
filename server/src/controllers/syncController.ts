
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/authMiddleware';
import { notifyClassManagers } from '../utils/notificationUtils';

const prisma = new PrismaClient();

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
                    for (const change of batch) {
                         const { entityType, operation, payload } = change;
                         const sanitizedPayload = sanitizePayload(payload);

                        if (entityType === 'NOTE' && operation === 'CREATE') {
                            const student = await prisma.student.findUnique({ where: { id: sanitizedPayload.studentId } });
                            if (student && student.classId && authorId) {
                                const author = await prisma.user.findUnique({ where: { id: authorId } });
                                const authorName = author?.name || 'A servant';
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
                                const cls = await prisma.class.findUnique({ where: { id: sanitizedPayload.classId } });
                                const author = await prisma.user.findUnique({ where: { id: authorId } });
                                const authorName = author?.name || 'A servant';
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

    // Fetch changes
    const students = await prisma.student.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const attendanceSessions = await prisma.attendanceSession.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const attendance = await prisma.attendanceRecord.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const notes = await prisma.note.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const classes = await prisma.class.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const users = await prisma.user.findMany({
        where: { updatedAt: { gt: sinceDate } },
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

    // Fetch class managers
    const classManagers = await prisma.classManager.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    res.json({
        serverTimestamp,
        changes: {
            students,
            attendance_sessions: attendanceSessions,
            attendance,
            notes,
            classes,
            users,
            class_managers: classManagers,
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
