import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/authMiddleware';
import { isClassManager, getUserManagedClassIds } from '../utils/authUtils';

const prisma = new PrismaClient();

export const createStudent = async (req: AuthRequest, res: Response) => {
    try {
        const { id, name, phone, classId, address, birthdate, createdAt, updatedAt } = req.body;
        const userId = req.user?.userId;
        const userRole = req.user?.role;

        if (!name) return res.status(400).json({ message: 'Name is required' });

        // Security Check
        if (userRole !== 'ADMIN' && userId && classId) {
            const isManager = await isClassManager(userId, classId as string);
            if (!isManager) {
                return res.status(403).json({ message: 'Forbidden: You do not manage this class' });
            }
        }

        const student = await prisma.student.create({
            data: {
                id: id as string,
                name: name as string,
                phone: phone as string | null,
                classId: classId as string,
                address: address as string | null,
                birthdate: birthdate ? new Date(birthdate as string) : null,
                createdAt: createdAt ? new Date(createdAt as string) : new Date(),
                updatedAt: updatedAt ? new Date(updatedAt as string) : new Date(),
                isDeleted: false,
            },
        });

        // Emit real-time update
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('sync_update', { entity: 'student', operation: 'create' });
        }

        res.status(201).json(student);
    } catch (error) {
        console.error('Create student error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

export const updateStudent = async (req: AuthRequest, res: Response) => {
    try {
        const id = String(req.params.id);
        const { name, phone, classId, address, birthdate, updatedAt, isDeleted } = req.body;
        const userId = req.user?.userId;
        const userRole = req.user?.role;

        if (!id) return res.status(400).json({ message: 'Student ID required' });

        // Security Check: Need to check current student class AND new class if changing
        if (userRole !== 'ADMIN' && userId) {
            const currentStudent = await prisma.student.findUnique({ where: { id } });
            if (!currentStudent) return res.status(404).json({ message: 'Student not found' });

            if (currentStudent.classId) {
                const isManagerCurrent = await isClassManager(userId, currentStudent.classId);
                if (!isManagerCurrent) return res.status(403).json({ message: 'Forbidden: You do not manage this student\'s class' });
            }

            if (classId && classId !== currentStudent.classId) {
                const isManagerNew = await isClassManager(userId, classId as string);
                if (!isManagerNew) return res.status(403).json({ message: 'Forbidden: You cannot move student to a class you do not manage' });
            }
        }

        const student = await prisma.student.update({
            where: { id },
            data: {
                ...(name && { name: name as string }),
                phone: phone as string | null,
                classId: classId as string,
                address: address as string | null,
                birthdate: birthdate ? new Date(birthdate as string) : (birthdate === null ? null : undefined),
                updatedAt: updatedAt ? new Date(updatedAt as string) : new Date(),
                ...(isDeleted !== undefined && { isDeleted: Boolean(isDeleted) }),
            },
        });

        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('sync_update', { entity: 'student', operation: 'update' });
        }

        res.json(student);
    } catch (error) {
        console.error('Update student error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

export const deleteStudent = async (req: AuthRequest, res: Response) => {
    try {
        const id = String(req.params.id);
        const userId = req.user?.userId;
        const userRole = req.user?.role;

        if (!id) return res.status(400).json({ message: 'Student ID required' });

        // Security Check
        if (userRole !== 'ADMIN' && userId) {
            const currentStudent = await prisma.student.findUnique({ where: { id } });
            if (!currentStudent) return res.status(404).json({ message: 'Student not found' });

            if (currentStudent.classId) {
                const isManager = await isClassManager(userId, currentStudent.classId);
                if (!isManager) return res.status(403).json({ message: 'Forbidden: You do not manage this student\'s class' });
            }
        }

        // Soft delete
        const student = await prisma.student.update({
            where: { id },
            data: {
                isDeleted: true,
                deletedAt: new Date(),
                updatedAt: new Date(),
            },
        });

        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('sync_update', { entity: 'student', operation: 'delete' });
        }

        res.json({ message: 'Student deleted', student });
    } catch (error) {
        console.error('Delete student error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

export const getStudents = async (req: AuthRequest, res: Response) => {
    try {
        const { classId } = req.query;
        const userId = req.user?.userId;
        const userRole = req.user?.role;

        const whereClause: any = { isDeleted: false };
        if (classId) {
            // If requesting specific class, verify permission
            if (userRole !== 'ADMIN' && userId) {
                const isManager = await isClassManager(userId, String(classId));
                if (!isManager) return res.status(403).json({ message: 'Forbidden' });
            }
            whereClause.classId = String(classId);
        } else {
            // If requesting all, filter to managed classes
            if (userRole !== 'ADMIN' && userId) {
                const managedClassIds = await getUserManagedClassIds(userId);
                whereClause.classId = { in: managedClassIds };
            }
        }

        const students = await prisma.student.findMany({
            where: whereClause,
            orderBy: { name: 'asc' },
        });

        res.json(students);
    } catch (error) {
        console.error('Get students error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};
