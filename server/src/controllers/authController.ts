
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
        let token = (req.query.token as string) || req.body.token;

        if (!token) return res.status(400).json({ message: 'Token required' });

        // Sanitize
        token = String(token).trim();

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

        let confirmationToken = user.confirmationToken;

        if (!confirmationToken) {
            confirmationToken = generateOTP();
            await prisma.user.update({
                where: { id: user.id },
                data: { confirmationToken }
            });
        }
        // If existed, reuse it (no database update needed for token)

        sendConfirmationEmail(user.email, confirmationToken as string).catch(console.error);

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

        let resetToken = user.passwordResetToken;
        let expires = user.passwordResetExpires;

        // Reuse existing token if it's still valid for at least 5 minutes (to give user time)
        // Or simply if it is valid at all.
        const isTokenValid = resetToken && expires && expires.getTime() > Date.now();

        if (!isTokenValid) {
            resetToken = generateOTP();
            expires = new Date(Date.now() + 3600000); // 1 hour

            await prisma.user.update({
                where: { id: user.id },
                data: {
                    passwordResetToken: resetToken,
                    passwordResetExpires: expires
                }
            });
        }
        // If valid, we just reuse 'resetToken' without updating DB (unless we want to extend time, but user said "resend old one")

        if (user.email === identifier) {
            await sendPasswordResetEmail(user.email, resetToken as string);
        } else if (user.phone === identifier) {
            await sendPasswordResetSms(user.phone!, resetToken as string);
        } else {
            if (user.email) await sendPasswordResetEmail(user.email, resetToken as string);
            else if (user.phone) await sendPasswordResetSms(user.phone, resetToken as string);
        }

        res.json({ message: 'If an account exists, a reset code has been sent' });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const verifyResetOtp = async (req: Request, res: Response) => {
    try {
        let { token } = req.body;
        if (!token) return res.status(400).json({ message: 'Token required' });

        // Sanitize token
        token = String(token).trim();

        console.log(`[VERIFY_RESET] Received token: '${token}'`);

        const user = await prisma.user.findFirst({
            where: {
                passwordResetToken: token,
                passwordResetExpires: { gt: new Date() },
                isDeleted: false
            }
        });

        if (!user) {
            // Debug why it failed
            const debugUser = await prisma.user.findFirst({ where: { passwordResetToken: token } });
            if (debugUser) {
                console.log(`[VERIFY_RESET] Token found for user ${debugUser.email}, but expired or deleted.`);
                console.log(`[VERIFY_RESET] Expires: ${debugUser.passwordResetExpires}, Now: ${new Date()}`);
            } else {
                console.log(`[VERIFY_RESET] Token '${token}' NOT found in DB.`);
            }
            return res.status(400).json({ message: 'Invalid or expired token', code: 'INVALID_TOKEN' });
        }

        console.log(`[VERIFY_RESET] Success for user: ${user.email}`);
        res.json({ message: 'Token is valid' });
    } catch (error) {
        console.error('Verify OTP error:', error);
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
            return res.status(400).json({ message: 'Invalid or expired token', code: 'INVALID_TOKEN' });
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
import { OAuth2Client } from 'google-auth-library';

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const googleLogin = async (req: Request, res: Response) => {
    try {
        const { idToken } = req.body;
        if (!idToken) {
            return res.status(400).json({ message: 'Missing ID Token' });
        }

        // 1. Verify Token
        const ticket = await client.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID,
        });

        const payload = ticket.getPayload();
        if (!payload) {
            return res.status(400).json({ message: 'Invalid token payload' });
        }

        const { email, name, picture, sub: googleId } = payload;

        if (!email) {
            return res.status(400).json({ message: 'Email not provided by Google' });
        }

        // 2. Find or Create User
        // We check for Google ID (future proofing) or Email
        let user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email }, // Link by email
                    // { googleId } // If you add googleId column later
                ],
                isDeleted: false
            }
        });

        if (!user) {
            // Register new user automatically
            // Auto-confirm email since it's verified by Google
            const userCount = await prisma.user.count({ where: { isDeleted: false } });
            const role = userCount === 0 ? 'ADMIN' : 'SERVANT';

            user = await prisma.user.create({
                data: {
                    email,
                    name: name || 'Google User',
                    password: await bcrypt.hash(Math.random().toString(36), 10), // Random password
                    role,
                    isEmailConfirmed: true,
                    isEnabled: true,
                    isActive: role === 'ADMIN', // Auto-activate if first admin, else pending logic? 
                    // Actually, social login usually implies "active" enough, 
                    // but let's respect the "waitActivation" rule if needed.
                    // For now, let's keep consistent:
                    activationDenied: false,
                    // photoUrl: picture // Add to schema if needed
                }
            });

            // Notify admins
            notifyAdmins(
                'newUserRegistered',
                '👤 New Google User',
                `${user.name} signed up with Google`,
                { userId: user.id },
                user.id
            ).catch(console.error);

        } else {
            // Optional: Update existing user info (e.g. name/photo) if login success?
            // For now, simple login.
        }

        // 3. Check access rules
        if (!user.isEnabled) {
            return res.status(403).json({
                message: 'Your account has been disabled by the administrator',
                code: 'ACCOUNT_DISABLED'
            });
        }

        // 4. Generate Session Token (Standard JWT)
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
                isEmailConfirmed: user.isEmailConfirmed
            }
        });

    } catch (error) {
        console.error('Google login error:', error);
        res.status(500).json({ message: 'Google authentication failed', error });
    }
};
