import { Server, Socket } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

let io: Server | null = null;

// Extend Socket interface to include user info
interface AuthenticatedSocket extends Socket {
    user?: {
        userId: string;
        role: string;
    };
}

export const initSocket = (httpServer: HttpServer): Server => {
    io = new Server(httpServer, {
        cors: {
            origin: "*", // Allow all origins for mobile app
            methods: ["GET", "POST"]
        }
    });

    // Authentication Middleware
    io.use((socket: AuthenticatedSocket, next) => {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization;

        if (!token) {
            return next(new Error('Authentication error: Token required'));
        }

        // Clean token if it starts with "Bearer "
        const tokenString = token.startsWith('Bearer ') ? token.slice(7) : token;

        jwt.verify(tokenString, JWT_SECRET, (err: any, decoded: any) => {
            if (err) {
                return next(new Error('Authentication error: Invalid token'));
            }
            socket.user = decoded;
            next();
        });
    });

    io.on('connection', (socket: AuthenticatedSocket) => {
        console.log('Client connected:', socket.id, 'User:', socket.user?.userId);

        if (!socket.user) {
            socket.disconnect();
            return;
        }

        const userId = socket.user.userId;
        const role = socket.user.role;

        // Automatically join user-specific room
        socket.join(`user_${userId}`);
        console.log(`Socket ${socket.id} joined room user_${userId}`);

        // Automatically join admins room if admin
        if (role === 'ADMIN') {
            socket.join('admins');
            console.log(`Socket ${socket.id} joined room admins`);
        }

        // Handle joining other rooms (e.g., class rooms) with authorization checks
        socket.on('join_room', (room: string) => {
            // Prevent joining other users' rooms or admin room manually without permission
            if (room.startsWith('user_') && room !== `user_${userId}`) {
                console.warn(`User ${userId} attempted to join unauthorized room ${room}`);
                return; // Silently ignore or emit error
            }

            if (room === 'admins' && role !== 'ADMIN') {
                console.warn(`User ${userId} attempted to join unauthorized room admins`);
                return;
            }

            console.log(`Socket ${socket.id} joining room ${room}`);
            socket.join(room);
        });

        socket.on('leave_room', (room: string) => {
             console.log(`Socket ${socket.id} leaving room ${room}`);
             socket.leave(room);
        });

        socket.on('disconnect', () => {
            console.log('Client disconnected:', socket.id);
        });
    });

    return io;
};

export const getIO = (): Server => {
    if (!io) {
        throw new Error('Socket.io not initialized');
    }
    return io;
};
