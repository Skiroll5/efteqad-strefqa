
import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { notifyAdmins } from '../utils/notificationUtils';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

export const register = async (req: Request, res: Response) => {
    try {
        const { email, password, name, role } = req.body;

        // Check for existing user (including deleted ones with same email)
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            // If user exists but is deleted, they can re-register
            if (!existingUser.isDeleted) {
                return res.status(400).json({
                    message: 'An account with this email already exists',
                    code: 'EMAIL_EXISTS'
                });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const userRole = role === 'ADMIN' ? 'ADMIN' : 'SERVANT';

        // If it's the FIRST user, make them ADMIN automatically
        const userCount = await prisma.user.count({ where: { isDeleted: false } });
        const finalRole = userCount === 0 ? 'ADMIN' : userRole;
        const isFirstAdmin = finalRole === 'ADMIN' && userCount === 0;

        // If existing deleted user, update instead of create
        let user;
        if (existingUser && existingUser.isDeleted) {
            user = await prisma.user.update({
                where: { id: existingUser.id },
                data: {
                    password: hashedPassword,
                    name,
                    role: finalRole,
                    isActive: isFirstAdmin,
                    isEnabled: true,
                    activationDenied: false,
                    isDeleted: false,
                    deletedAt: null,
                    updatedAt: new Date(),
                },
            });
        } else {
            user = await prisma.user.create({
                data: {
                    email,
                    password: hashedPassword,
                    name,
                    role: finalRole,
                    isActive: isFirstAdmin,
                    isEnabled: true,
                    activationDenied: false,
                },
            });
        }

        // Notify admins about new registration
        if (!isFirstAdmin) {
            notifyAdmins(
                'newUserRegistered',
                '👤 New Registration',
                `${user.name} registered and is waiting for approval`,
                { userId: user.id },
                user.id
            ).catch(err => console.error('Notification error:', err));
        }

        // Emit real-time update
        const io = (req as any).app?.get('io');
        if (io) {
            io.emit('user_registered', { userId: user.id });
        }

        res.status(201).json({
            message: 'Registration successful',
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                isActive: user.isActive,
                isEnabled: user.isEnabled
            }
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

export const login = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body;
        const user = await prisma.user.findUnique({ where: { email } });

        // User not found or deleted = invalid credentials
        if (!user || user.isDeleted) {
            return res.status(400).json({ message: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
        }

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
        }

        // Check if account is disabled by admin
        if (!user.isEnabled) {
            return res.status(403).json({
                message: 'Your account has been disabled by the administrator',
                code: 'ACCOUNT_DISABLED'
            });
        }

        // Generate token with longer expiry
        // Allow login for pending/denied users so they can see the pending screen
        const token = jwt.sign(
            { userId: user.id, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};
