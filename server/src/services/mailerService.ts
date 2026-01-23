import { Resend } from 'resend';

const resendApiKey = process.env.RESEND_API_KEY;
const fromEmail = process.env.FROM_EMAIL || 'onboarding@resend.dev';

// Initialize Resend only if API Key is present
const resend = resendApiKey ? new Resend(resendApiKey) : null;

export const sendConfirmationEmail = async (email: string, token: string) => {
    if (!resend) {
        console.log('\n--- EMAIL CONFIRMATION (MOCK) ---');
        console.log(`To: ${email}`);
        console.log(`OTP Code: ${token}`);
        console.log('---------------------------------\n');
        return;
    }

    try {
        await resend.emails.send({
            from: fromEmail,
            to: email,
            subject: 'Confirm your email',
            html: `
                <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2>Welcome!</h2>
                    <p>Please use the following code to confirm your email address:</p>
                    <div style="background-color: #f4f4f4; padding: 20px; text-align: center; border-radius: 8px; font-size: 24px; letter-spacing: 5px; font-weight: bold;">
                        ${token}
                    </div>
                    <p>If you didn't create an account, you can safely ignore this email.</p>
                </div>
            `
        });
        console.log(`Confirmation email sent to ${email}`);
    } catch (error) {
        console.error('Error sending confirmation email:', error);
    }
};

export const sendPasswordResetEmail = async (email: string, token: string) => {
    if (!resend) {
        console.log('\n--- PASSWORD RESET (MOCK) ---');
        console.log(`To: ${email}`);
        console.log(`OTP Code: ${token}`);
        console.log('-----------------------------\n');
        return;
    }

    try {
        await resend.emails.send({
            from: fromEmail,
            to: email,
            subject: 'Reset your password',
            html: `
                <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2>Reset Password</h2>
                    <p>You requested to reset your password. Use the code below:</p>
                    <div style="background-color: #f4f4f4; padding: 20px; text-align: center; border-radius: 8px; font-size: 24px; letter-spacing: 5px; font-weight: bold;">
                        ${token}
                    </div>
                    <p>This code will expire in 1 hour.</p>
                </div>
            `
        });
        console.log(`Password reset email sent to ${email}`);
    } catch (error) {
        console.error('Error sending password reset email:', error);
    }
};

export const sendPasswordResetSms = async (phone: string, token: string) => {
    // SMS integration would go here (e.g. Twilio)
    console.log('\n--- PASSWORD RESET (SMS MOCK) ---');
    console.log(`To: ${phone}`);
    console.log(`OTP Code: ${token}`);
    console.log('---------------------------------\n');
};
