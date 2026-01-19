import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import { Server } from 'socket.io';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import syncRoutes from './routes/syncRoutes';
import classRoutes from './routes/classRoutes';
import studentRoutes from './routes/studentRoutes';
import fcmRoutes from './routes/fcmRoutes';
import { initFirebase } from './services/notificationService';
import { initScheduledJobs } from './jobs/scheduledJobs';
import { setIO } from './socket';

const app = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server and Socket.io instance
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: "*", // Allow all origins for mobile app
        methods: ["GET", "POST"]
    }
});

// Set the socket instance for use in controllers
setIO(io);

// Attach io to app for use in controllers (legacy)
app.set('io', io);

app.use(cors());
app.use(helmet());
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/sync', syncRoutes);
app.use('/classes', classRoutes);
app.use('/students', studentRoutes);
app.use('/fcm', fcmRoutes);

app.get('/', (req, res) => {
    res.send('St. Refqa Efteqad API is running');
});

io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

const startServer = async () => {
    try {
        // Initialize Firebase Admin SDK
        await initFirebase();

        // Initialize Scheduled Jobs
        initScheduledJobs();

        httpServer.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
};

startServer();
