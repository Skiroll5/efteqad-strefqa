
import express from 'express';
import {
    activateUser,
    listPendingUsers,
    listAllUsers,
    enableUser,
    disableUser,
    updateProfile,
    saveStudentPreference,
    getStudentPreference
} from '../controllers/userController';
import { authenticateToken, requireAdmin } from '../middleware/authMiddleware';

const router = express.Router();

// Public/Self routes (Authenticated)
router.put('/me', authenticateToken, updateProfile);
router.put('/me/students/:studentId/preference', authenticateToken, saveStudentPreference);
router.get('/me/students/:studentId/preference', authenticateToken, getStudentPreference);

// Admin only routes
router.use(authenticateToken, requireAdmin);

router.get('/', listAllUsers);
router.get('/pending', listPendingUsers);
router.post('/activate', activateUser);
router.post('/:id/enable', enableUser);
router.post('/:id/disable', disableUser);

export default router;
