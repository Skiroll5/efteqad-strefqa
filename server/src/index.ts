import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import syncRoutes from './routes/syncRoutes';
import classRoutes from './routes/classRoutes';
import studentRoutes from './routes/studentRoutes';
import fcmRoutes from './routes/fcmRoutes';
import { initFirebase } from './services/notificationService';
import { initScheduledJobs } from './jobs/scheduledJobs';
import { initSocket } from './socket';

const app = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server
const httpServer = createServer(app);

// Initialize Socket.io
const io = initSocket(httpServer);

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
