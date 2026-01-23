
import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient, Role } from '@prisma/client';
import { notifyAdmins } from '../utils/notificationUtils';
import { sendConfirmationEmail, sendPasswordResetEmail, sendPasswordResetSms } from '../services/mailerService';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

// Helper to generate 6 digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

export const register = async (req: Request, res: Response) => {
    try {
        const { email, password, name, role, phone } = req.body;

        if (!email || !password || !name) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Check for existing user (including deleted ones with same email or phone)
        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [
                    { email },
                    ...(phone ? [{ phone }] : [])
                ]
            }
        });

        if (existingUser && !existingUser.isDeleted) {
            const conflictField = existingUser.email === email ? 'email' : 'phone';
            return res.status(400).json({
                message: `An account with this ${conflictField} already exists`,
                code: conflictField === 'email' ? 'EMAIL_EXISTS' : 'PHONE_EXISTS'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const userRole = role === 'ADMIN' ? 'ADMIN' : 'SERVANT';

        // If it's the FIRST user, make them ADMIN automatically
        const userCount = await prisma.user.count({ where: { isDeleted: false } });
        const finalRole = userCount === 0 ? 'ADMIN' : userRole;
        const isFirstAdmin = finalRole === 'ADMIN' && userCount === 0;

        // Generate email confirmation token (OTP)
        const confirmationToken = generateOTP();

        // If existing deleted user, update instead of create
        let user;
        if (existingUser && existingUser.isDeleted) {
            user = await prisma.user.update({
                where: { id: existingUser.id },
                data: {
                    email,
                    phone: phone || null,
                    password: hashedPassword,
                    name,
                    role: finalRole,
                    isActive: isFirstAdmin,
                    isEnabled: true,
                    activationDenied: false,
                    isDeleted: false,
                    deletedAt: null,
                    updatedAt: new Date(),
                    isEmailConfirmed: false,
                    confirmationToken,
                },
            });
        } else {
            user = await prisma.user.create({
                data: {
                    email,
                    phone: phone || null,
                    password: hashedPassword,
                    name,
                    role: finalRole,
                    isActive: isFirstAdmin,
                    isEnabled: true,
                    activationDenied: false,
                    isEmailConfirmed: false,
                    confirmationToken,
                },
            });
        }

        // Send confirmation email
        sendConfirmationEmail(user.email, confirmationToken).catch(err => console.error('Email error:', err));

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
        const { identifier, password } = req.body; // identifier can be email or phone

        if (!identifier || !password) {
            return res.status(400).json({ message: 'Missing credentials' });
        }

        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: identifier },
                    { phone: identifier }
                ],
                isDeleted: false
            }
        });

        // User not found or deleted = invalid credentials
        if (!user) {
            return res.status(400).json({ message: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
        }

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
        }

        // Check if email is confirmed (only if signing in with email or if user has email)
        if (!user.isEmailConfirmed) {
            return res.status(403).json({
                message: 'Please confirm your email before logging in',
                code: 'EMAIL_NOT_CONFIRMED'
            });
        }

        // Check if account is disabled by admin
        if (!user.isEnabled) {
            return res.status(403).json({
                message: 'Your account has been disabled by the administrator',
                code: 'ACCOUNT_DISABLED'
            });
        }

        // Generate token with longer expiry
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
                phone: user.phone,
                name: user.name,
                role: user.role,
                isActive: user.isActive,
                isEnabled: user.isEnabled,
                activationDenied: user.activationDenied,
                isEmailConfirmed: user.isEmailConfirmed
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error', error });
    }
};

export const confirmEmail = async (req: Request, res: Response) => {
    try {
        // Support both query (link) and body (OTP)
        const token = (req.query.token as string) || req.body.token;

        if (!token) return res.status(400).json({ message: 'Token required' });

        const user = await prisma.user.findFirst({
            where: { confirmationToken: token, isDeleted: false }
        });

        if (!user) {
            return res.status(400).json({ message: 'Invalid or expired token' });
        }

        await prisma.user.update({
            where: { id: user.id },
            data: {
                isEmailConfirmed: true,
                confirmationToken: null,
                updatedAt: new Date()
            }
        });

        res.json({ message: 'Email confirmed successfully' });
    } catch (error) {
        console.error('Confirm email error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const resendConfirmation = async (req: Request, res: Response) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email required' });

        const user = await prisma.user.findFirst({
            where: { email, isDeleted: false }
        });

        if (!user) return res.status(404).json({ message: 'User not found' });
        if (user.isEmailConfirmed) return res.status(400).json({ message: 'Email already confirmed' });

        const confirmationToken = generateOTP();

        await prisma.user.update({
            where: { id: user.id },
            data: { confirmationToken }
        });

        sendConfirmationEmail(user.email, confirmationToken).catch(console.error);

        res.json({ message: 'Confirmation code sent' });
    } catch (error) {
        console.error('Resend error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const forgotPassword = async (req: Request, res: Response) => {
    try {
        const { identifier } = req.body; // email or phone
        if (!identifier) return res.status(400).json({ message: 'Identifier required' });

        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: identifier },
                    { phone: identifier }
                ],
                isDeleted: false
            }
        });

        if (!user) {
            return res.json({ message: 'If an account exists, a reset code has been sent' });
        }

        const resetToken = generateOTP();
        const expires = new Date(Date.now() + 3600000); // 1 hour

        await prisma.user.update({
            where: { id: user.id },
            data: {
                passwordResetToken: resetToken,
                passwordResetExpires: expires
            }
        });

        if (user.email === identifier) {
            await sendPasswordResetEmail(user.email, resetToken);
        } else if (user.phone === identifier) {
            await sendPasswordResetSms(user.phone!, resetToken);
        } else {
            if (user.email) await sendPasswordResetEmail(user.email, resetToken);
            else if (user.phone) await sendPasswordResetSms(user.phone, resetToken);
        }

        res.json({ message: 'If an account exists, a reset code has been sent' });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const resetPassword = async (req: Request, res: Response) => {
    try {
        const { token, newPassword } = req.body;
        if (!token || !newPassword) return res.status(400).json({ message: 'Token and new password required' });

        const user = await prisma.user.findFirst({
            where: {
                passwordResetToken: token,
                passwordResetExpires: { gt: new Date() },
                isDeleted: false
            }
        });

        if (!user) {
            return res.status(400).json({ message: 'Invalid or expired token' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        await prisma.user.update({
            where: { id: user.id },
            data: {
                password: hashedPassword,
                passwordResetToken: null,
                passwordResetExpires: null,
                updatedAt: new Date()
            }
        });

        res.json({ message: 'Password reset successful' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};
