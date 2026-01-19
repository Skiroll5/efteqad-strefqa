
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { getIO } from '../socket';

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

        const classesWithStats = classes.map((cls) => {
            let totalRecords = 0;
            let presentRecords = 0;

            cls.sessions.forEach((session) => {
                session.records.forEach((record) => {
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
                    .map((m) => m.user.name)
                    .filter((n) => n)
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
        const { name, grade } = req.body;
        if (!name) return res.status(400).json({ message: 'Class name required' });

        const newClass = await prisma.class.create({
            data: { name, grade },
        });

        res.status(201).json({ message: 'Class created', class: newClass });

        // Emit real-time update
        const io = getIO();
        io.emit('sync_update');
    } catch (error) {
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

        // Emit sync update event so all clients refresh
        const io = getIO();
        io.emit('sync_update');
        // Also emit a specific event to the affected user
        io.emit('manager_assignment_changed', { classId, userId, action: 'assigned' });

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

        // Emit sync update event so all clients refresh
        const io = getIO();
        io.emit('sync_update');
        // Also emit a specific event to the affected user
        io.emit('manager_assignment_changed', { classId, userId, action: 'removed' });

        res.json({ message: 'Manager removed' });
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
            .filter(m => m.user !== null)
            .map(m => m.user);

        res.json(flattenedManagers);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
