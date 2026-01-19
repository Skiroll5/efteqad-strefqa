import express from 'express';
import { createStudent, updateStudent, deleteStudent, getStudents } from '../controllers/studentController';
import { authenticateToken } from '../middleware/authMiddleware';

const router = express.Router();

router.use(authenticateToken); // Protect all routes

router.get('/', getStudents);
router.post('/', createStudent);
router.put('/:id', updateStudent);
router.delete('/:id', deleteStudent);

export default router;
