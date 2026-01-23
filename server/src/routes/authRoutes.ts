import express from 'express';
import { register, login, confirmEmail, forgotPassword, resetPassword, resendConfirmation } from '../controllers/authController';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/confirm-email', confirmEmail); // Changed to post for OTP verification
router.get('/confirm-email', confirmEmail); // Keep get for backward compatibility/links
router.post('/resend-confirmation', resendConfirmation);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

export default router;
