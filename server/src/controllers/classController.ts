
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// List all classes with their managers
export const listClasses = async (req: Request, res: Response) => {
    try {
        const classes = await prisma.class.findMany({
            where: { isDeleted: false },
            include: {
                managers: {
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
                attendancePercentage
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

        // Check if manager relationship already exists
        const existing = await prisma.classManager.findUnique({
            where: { classId_userId: { classId, userId } },
        });

        if (existing) {
            return res.status(409).json({ message: 'User is already a manager of this class' });
        }

        const manager = await prisma.classManager.create({
            data: { classId, userId },
            include: {
                user: { select: { id: true, name: true, email: true } },
                class: { select: { id: true, name: true } },
            },
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

        await prisma.classManager.delete({
            where: { classId_userId: { classId, userId } },
        });

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
            where: { classId },
            include: {
                user: { select: { id: true, name: true, email: true } },
            },
        });

        res.json(managers);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
