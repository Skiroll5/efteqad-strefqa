import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import { Server } from 'socket.io';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import syncRoutes from './routes/syncRoutes';
import classRoutes from './routes/classRoutes';

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

// Attach io to app for use in controllers
app.set('io', io);

app.use(cors());
app.use(helmet());
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/sync', syncRoutes);
app.use('/classes', classRoutes);

app.get('/', (req, res) => {
    res.send('St. Refqa Efteqad API is running');
});

io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

httpServer.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
