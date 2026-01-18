
import express from 'express';
import {
    listClasses,
    createClass,
    assignManager,
    removeManager,
    getClassManagers
} from '../controllers/classController';
import { authenticateToken, requireAdmin } from '../middleware/authMiddleware';

const router = express.Router();

// All class management routes require authentication and admin role
router.use(authenticateToken, requireAdmin);

// GET /classes - List all classes with managers
router.get('/', listClasses);

// POST /classes - Create a new class
router.post('/', createClass);

// GET /classes/:id/managers - Get all managers for a class
router.get('/:id/managers', getClassManagers);

// POST /classes/:id/managers - Assign a manager to a class
router.post('/:id/managers', assignManager);

// DELETE /classes/:classId/managers/:userId - Remove a manager from a class
router.delete('/:classId/managers/:userId', removeManager);

export default router;
