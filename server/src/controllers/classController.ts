
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { getIO } from '../socket';
import { emitAppNotification } from '../utils/realtimeNotifications';

const prisma = new PrismaClient();

// List all classes with their managers
export const listClasses = async (req: Request, res: Response) => {
    try {
        const classes = await prisma.class.findMany({
            where: { isDeleted: false },
            include: {
                managers: {
                    where: { isDeleted: false },
                    select: {
                        user: {
                            select: {
                                id: true,
                                name: true,
                                email: true
                            }
                        }
                    }
                },
                sessions: {
                    where: { isDeleted: false },
                    select: {
                        records: {
                            where: { isDeleted: false },
                            select: { status: true }
                        }
                    }
                }
            },
            orderBy: { name: 'asc' },
        });

        const classesWithStats = classes.map((cls: any) => {
            let totalRecords = 0;
            let presentRecords = 0;

            cls.sessions.forEach((session: any) => {
                session.records.forEach((record: any) => {
                    totalRecords++;
                    if (record.status === 'PRESENT') {
                        presentRecords++;
                    }
                });
            });

            const attendancePercentage = totalRecords > 0
                ? presentRecords / totalRecords
                : 0;

            // Remove sessions from response to keep it light
            const { sessions, ...classData } = cls;
            return {
                ...classData,
                attendancePercentage,
                managerNames: cls.managers
                    .map((m: any) => m.user.name)
                    .filter((n: any) => n)
                    .join(', ')
            };
        });

        res.json(classesWithStats);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

// Create a new class
export const createClass = async (req: Request, res: Response) => {
    try {
        const { id, name, managers } = req.body;
        if (!name) return res.status(400).json({ message: 'Class name required' });

        const managerIds: string[] = Array.isArray(managers) ? managers : [];

        const newClass = await prisma.class.create({
            data: {
                id: id || undefined, // Use provided ID if available
                name,
                managers: {
                    create: managerIds.map((userId) => ({
                        userId
                    }))
                }
            },
        });

        res.status(201).json({ message: 'Class created', class: newClass });

        // Emit real-time update
        const io = getIO();
        io.emit('sync_update');

        // Notify assigned managers
        managerIds.forEach(userId => {
            io.emit('manager_assignment_changed', { classId: newClass.id, userId, action: 'assigned' });
            emitAppNotification({
                level: 'success',
                title: 'Assigned to Class',
                message: `You have been assigned as a manager to ${newClass.name}.`,
                audience: 'admins', // Technically audience is specific user
                targetUserId: userId,
                entityType: 'CLASS_MANAGER',
                classId: newClass.id,
            });
        });

    } catch (error) {
        console.error('Create class error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

// Assign a user as class manager
export const assignManager = async (req: Request, res: Response) => {
    try {
        const classId = req.params.id as string;
        const { userId } = req.body;

        if (!classId || !userId) {
            return res.status(400).json({ message: 'Class ID and User ID required' });
        }

        const manager = await prisma.classManager.upsert({
            where: { classId_userId: { classId, userId } },
            update: { isDeleted: false, deletedAt: null },
            create: { classId, userId },
            include: {
                user: { select: { id: true, name: true, email: true } },
                class: { select: { id: true, name: true } },
            },
        });

        // Touch the class updatedAt so sync picks up the new manager list
        await prisma.class.update({
            where: { id: classId },
            data: { updatedAt: new Date() }
        });

        // Emit sync update event so all clients refresh
        const io = getIO();
        io.emit('sync_update');
        // Also emit a specific event to the affected user
        io.emit('manager_assignment_changed', { classId, userId, action: 'assigned' });
        emitAppNotification({
            level: 'success',
            title: 'Manager assigned',
            message: `${manager.user?.name ?? 'User'} was assigned to ${manager.class?.name ?? 'class'}.`,
            audience: 'admins',
            targetUserId: userId,
            entityType: 'CLASS_MANAGER',
            entityId: manager.id,
            classId,
        });

        res.status(201).json({ message: 'Manager assigned', manager });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

// Remove a user as class manager
export const removeManager = async (req: Request, res: Response) => {
    try {
        const classId = req.params.classId as string;
        const userId = req.params.userId as string;

        if (!classId || !userId) {
            return res.status(400).json({ message: 'Class ID and User ID required' });
        }

        await prisma.classManager.update({
            where: { classId_userId: { classId, userId } },
            data: {
                isDeleted: true,
                deletedAt: new Date(),
            }
        });

        // Touch the class updatedAt so sync picks up the new manager list
        await prisma.class.update({
            where: { id: classId },
            data: { updatedAt: new Date() }
        });

        // Emit sync update event so all clients refresh
        const io = getIO();
        io.emit('sync_update');
        // Also emit a specific event to the affected user
        io.emit('manager_assignment_changed', { classId, userId, action: 'removed' });
        emitAppNotification({
            level: 'warning',
            title: 'Manager removed',
            message: `A manager was removed from a class.`,
            audience: 'admins',
            targetUserId: userId,
            entityType: 'CLASS_MANAGER',
            classId,
        });

        res.json({ message: 'Manager removed' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

// Update a class
export const updateClass = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const { name } = req.body;

        if (!id || !name) {
            return res.status(400).json({ message: 'Class ID and name required' });
        }

        const updatedClass = await prisma.class.update({
            where: { id },
            data: {
                name,
                updatedAt: new Date()
            }
        });

        res.json({ message: 'Class updated', class: updatedClass });

        // Real-time update
        const io = getIO();
        io.emit('sync_update');
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

// Delete a class
export const deleteClass = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;

        if (!id) {
            return res.status(400).json({ message: 'Class ID required' });
        }

        // Soft delete class
        await prisma.class.update({
            where: { id },
            data: {
                isDeleted: true,
                deletedAt: new Date(),
                updatedAt: new Date()
            }
        });

        // Also soft delete related sessions/managers? 
        // Logic might vary, but usually we cascade delete or just leave them orphans if we want history.
        // For sync consistency, let's touch them or just rely on client filtering.
        // But strictly, we should mark valid relations as deleted OR just rely on 'isDeleted' prop of Class.

        res.json({ message: 'Class deleted' });

        // Real-time update
        const io = getIO();
        io.emit('sync_update');
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

// Get all managers for a specific class
export const getClassManagers = async (req: Request, res: Response) => {
    try {
        const classId = req.params.id as string;

        if (!classId) {
            return res.status(400).json({ message: 'Class ID required' });
        }

        const managers = await prisma.classManager.findMany({
            where: { classId, isDeleted: false },
            include: {
                user: { select: { id: true, name: true, email: true } },
            },
        });

        // Flatten the response to return the users directly, filtering out null users
        const flattenedManagers = managers
            .filter((m: any) => m.user !== null)
            .map((m: any) => m.user);

        res.json(flattenedManagers);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
