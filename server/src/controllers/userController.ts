
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const activateUser = async (req: Request, res: Response) => {
    try {
        const { userId } = req.body;
        if (!userId) return res.status(400).json({ message: 'UserId required' });

        const user = await prisma.user.update({
            where: { id: userId },
            data: { isActive: true },
        });

        res.json({ message: 'User activated', user: { id: user.id, isActive: user.isActive } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const listPendingUsers = async (req: Request, res: Response) => {
    try {
        const users = await prisma.user.findMany({
            where: { isActive: false, role: 'SERVANT', isDeleted: false },
            select: { id: true, name: true, email: true, createdAt: true },
        });
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const listAllUsers = async (req: Request, res: Response) => {
    try {
        const users = await prisma.user.findMany({
            where: { isDeleted: false },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                isActive: true,
                createdAt: true,
                // TODO: uncomment after running: npx prisma generate
                // managedClasses: {
                //     select: {
                //         class: {
                //             select: { id: true, name: true }
                //         }
                //     }
                // }
            },
            orderBy: { createdAt: 'desc' },
        });
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const enableUser = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        if (!id) return res.status(400).json({ message: 'User ID required' });

        const user = await prisma.user.update({
            where: { id },
            data: { isActive: true },
        });

        res.json({ message: 'User enabled', user: { id: user.id, isActive: user.isActive } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const disableUser = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        if (!id) return res.status(400).json({ message: 'User ID required' });

        const user = await prisma.user.update({
            where: { id },
            data: { isActive: false },
        });

        res.json({ message: 'User disabled', user: { id: user.id, isActive: user.isActive } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const updateProfile = async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user?.userId;
        const { whatsappTemplate, name } = req.body;

        if (!userId) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                ...(name && { name }),
                ...(whatsappTemplate !== undefined && { whatsappTemplate }),
            },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                whatsappTemplate: true,
            }
        });

        res.json({ message: 'Profile updated', user: updatedUser });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const saveStudentPreference = async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user?.userId;
        const studentId: string = String(req.params.studentId);
        const { customWhatsappMessage } = req.body;

        if (!userId) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        if (!studentId) {
            return res.status(400).json({ message: 'Student ID required' });
        }

        const preference = await prisma.userStudentPreference.upsert({
            where: {
                userId_studentId: { userId, studentId },
            },
            update: {
                customWhatsappMessage,
            },
            create: {
                userId,
                studentId,
                customWhatsappMessage,
            },
        });

        res.json({ message: 'Preference saved', preference });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const getStudentPreference = async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user?.userId;
        const studentId: string = String(req.params.studentId);

        if (!userId) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        if (!studentId) {
            return res.status(400).json({ message: 'Student ID required' });
        }

        const preference = await prisma.userStudentPreference.findUnique({
            where: {
                userId_studentId: { userId, studentId },
            },
        });

        res.json(preference || { customWhatsappMessage: null });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
