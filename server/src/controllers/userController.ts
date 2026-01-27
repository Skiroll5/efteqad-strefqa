
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { notifyUser } from '../utils/notificationUtils';
import { emitAppNotification } from '../utils/realtimeNotifications';

const prisma = new PrismaClient();

export const activateUser = async (req: Request, res: Response) => {
    try {
        const { userId } = req.body;
        if (!userId) return res.status(400).json({ message: 'UserId required' });

        const user = await prisma.user.update({
            where: { id: userId },
            data: {
                isActive: true,
                activationDenied: false,
                updatedAt: new Date()
            },
        });

        notifyUser(
            user.id,
            '✅ Account Approved',
            'Your account has been activated!'
        ).catch(err => console.error('Notification error:', err));

        // Emit real-time update
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_status_changed', {
                userId: user.id,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied
            });
        }
        emitAppNotification({
            level: 'success',
            title: 'User activated',
            message: `${user.name} is now active.`,
            audience: 'admins',
            targetUserId: user.id,
            entityType: 'USER',
            entityId: user.id,
        });

        res.json({ message: 'User activated', user: { id: user.id, isActive: user.isActive } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const abortActivation = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        if (!id) return res.status(400).json({ message: 'User ID required' });

        const user = await prisma.user.update({
            where: { id },
            data: {
                activationDenied: true,
                isActive: false,
                updatedAt: new Date()
            },
        });

        notifyUser(
            user.id,
            '❌ Activation Denied',
            'Your activation request was denied by the administrator.'
        ).catch(err => console.error('Notification error:', err));

        // Emit real-time update
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_status_changed', {
                userId: user.id,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied
            });
        }
        emitAppNotification({
            level: 'warning',
            title: 'Activation denied',
            message: `${user.name}'s activation was denied.`,
            audience: 'admins',
            targetUserId: user.id,
            entityType: 'USER',
            entityId: user.id,
        });

        res.json({ message: 'User activation denied', user: { id: user.id, activationDenied: user.activationDenied } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const listPendingUsers = async (req: Request, res: Response) => {
    try {
        const users = await prisma.user.findMany({
            where: {
                isActive: false,
                isEnabled: true,
                activationDenied: false,
                role: 'SERVANT',
                isDeleted: false
            },
            select: { id: true, name: true, email: true, createdAt: true },
        });
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const listAbortedUsers = async (req: Request, res: Response) => {
    try {
        const users = await prisma.user.findMany({
            where: {
                activationDenied: true,
                isDeleted: false
            },
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
            where: {
                isDeleted: false
            },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                isActive: true,
                isEnabled: true,
                activationDenied: true,
                createdAt: true,
                managedClasses: {
                    select: {
                        class: {
                            select: { id: true, name: true }
                        }
                    }
                }
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
            data: {
                isEnabled: true,
                updatedAt: new Date()
            },
        });

        notifyUser(
            user.id,
            '✅ Account Enabled',
            'Your account has been re-enabled.'
        ).catch(err => console.error('Notification error:', err));

        // Emit real-time update
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_status_changed', {
                userId: user.id,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied
            });
        }
        emitAppNotification({
            level: 'success',
            title: 'User enabled',
            message: `${user.name} can sign in again.`,
            audience: 'admins',
            targetUserId: user.id,
            entityType: 'USER',
            entityId: user.id,
        });

        res.json({ message: 'User enabled', user: { id: user.id, isEnabled: user.isEnabled } });
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
            data: {
                isEnabled: false,
                updatedAt: new Date()
            },
        });

        notifyUser(
            user.id,
            '⚠️ Account Disabled',
            'Your account has been disabled by the administrator.'
        ).catch(err => console.error('Notification error:', err));

        // Emit real-time update - this will trigger auto-logout on client
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_disabled', { userId: user.id });
            io.emit('user_status_changed', {
                userId: user.id,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied
            });
        }
        emitAppNotification({
            level: 'warning',
            title: 'User disabled',
            message: `${user.name} has been disabled.`,
            audience: 'admins',
            targetUserId: user.id,
            entityType: 'USER',
            entityId: user.id,
        });

        res.json({ message: 'User disabled', user: { id: user.id, isEnabled: user.isEnabled } });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const deleteUser = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        if (!id) return res.status(400).json({ message: 'User ID required' });

        const user = await prisma.user.update({
            where: { id },
            data: {
                isDeleted: true,
                deletedAt: new Date(),
                updatedAt: new Date()
            },
        });

        // Emit real-time update - this will trigger auto-logout on client
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_deleted', { userId: user.id });
            io.emit('user_status_changed', {
                userId: user.id,
                isDeleted: true
            });
        }
        emitAppNotification({
            level: 'warning',
            title: 'User deleted',
            message: `${user.name} was deleted.`,
            audience: 'admins',
            targetUserId: user.id,
            entityType: 'USER',
            entityId: user.id,
        });

        res.json({ message: 'User deleted', user: { id: user.id } });
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
            // select: {
            //     id: true,
            //     name: true,
            //     email: true,
            //     role: true,
            //     whatsappTemplate: true,
            // }
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

export const getNotificationPreferences = async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user?.userId;
        if (!userId) return res.status(401).json({ message: 'Unauthorized' });

        const prefs = await prisma.notificationPreference.findUnique({
            where: { userId },
        });

        // Return default values if no record exists
        if (!prefs) {
            return res.json({
                noteAdded: true,
                noteUpdated: true,
                attendanceRecorded: true,
                birthdayReminder: true,
                inactiveStudent: true,
                newUserRegistered: true,
                inactiveThresholdDays: 14,
                birthdayNotifyMorning: true,
            });
        }

        res.json(prefs);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};

export const updateNotificationPreferences = async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user?.userId;
        if (!userId) return res.status(401).json({ message: 'Unauthorized' });

        const {
            noteAdded,
            noteUpdated,
            attendanceRecorded,
            birthdayReminder,
            inactiveStudent,
            newUserRegistered,
            inactiveThresholdDays,
            birthdayNotifyMorning
        } = req.body;

        const prefs = await prisma.notificationPreference.upsert({
            where: { userId },
            update: {
                ...(noteAdded !== undefined && { noteAdded }),
                ...(noteUpdated !== undefined && { noteUpdated }),
                ...(attendanceRecorded !== undefined && { attendanceRecorded }),
                ...(birthdayReminder !== undefined && { birthdayReminder }),
                ...(inactiveStudent !== undefined && { inactiveStudent }),
                ...(newUserRegistered !== undefined && { newUserRegistered }),
                ...(inactiveThresholdDays !== undefined && { inactiveThresholdDays }),
                ...(birthdayNotifyMorning !== undefined && { birthdayNotifyMorning }),
            },
            create: {
                userId,
                noteAdded: noteAdded ?? true,
                noteUpdated: noteUpdated ?? true,
                attendanceRecorded: attendanceRecorded ?? true,
                birthdayReminder: birthdayReminder ?? true,
                inactiveStudent: inactiveStudent ?? true,
                newUserRegistered: newUserRegistered ?? true,
                inactiveThresholdDays: inactiveThresholdDays ?? 14,
                birthdayNotifyMorning: birthdayNotifyMorning ?? true,
            },
        });

        res.json({ message: 'Preferences updated', prefs });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
