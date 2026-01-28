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
            subject: 'تأكيد بريدك الإلكتروني',
            html: `
                <!DOCTYPE html>
                <html dir="rtl" lang="ar">
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; margin: 0; padding: 0; }
                        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #e0e0e0; text-align: right; direction: rtl; }
                        h2 { color: #1a1a1a; margin-top: 0; font-size: 24px; }
                        p { color: #4a4a4a; font-size: 16px; line-height: 1.6; }
                        .otp-box { background-color: #f0f7ff; color: #0066cc; padding: 20px; text-align: center; border-radius: 8px; font-size: 32px; letter-spacing: 8px; font-weight: bold; margin: 30px 0; border: 1px dashed #cce5ff; }
                        .footer { margin-top: 30px; font-size: 14px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>مرحباً بك!</h2>
                        <p>شكراً لتسجيلك معنا. يرجى استخدام رمز التحقق التالي لتأكيد عنوان بريدك الإلكتروني:</p>
                        
                        <div class="otp-box">
                            ${token}
                        </div>
                        
                        <p>إذا لم تقم بإنشاء حساب، يمكنك تجاهل هذا البريد الإلكتروني بأمان.</p>
                        
                        <div class="footer">
                            برنامج وديعة - كنيسة القديسة رفقة
                        </div>
                    </div>
                </body>
                </html>
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
            subject: 'إعادة تعيين كلمة المرور',
            html: `
                <!DOCTYPE html>
                <html dir="rtl" lang="ar">
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; margin: 0; padding: 0; }
                        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #e0e0e0; text-align: right; direction: rtl; }
                        h2 { color: #1a1a1a; margin-top: 0; font-size: 24px; }
                        p { color: #4a4a4a; font-size: 16px; line-height: 1.6; }
                        .otp-box { background-color: #fff0f0; color: #d32f2f; padding: 20px; text-align: center; border-radius: 8px; font-size: 32px; letter-spacing: 8px; font-weight: bold; margin: 30px 0; border: 1px dashed #ffcdd2; }
                        .footer { margin-top: 30px; font-size: 14px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>إعادة تعيين كلمة المرور</h2>
                        <p>لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك. استخدم الرمز التالي لإتمام العملية:</p>
                        
                        <div class="otp-box">
                            ${token}
                        </div>
                        
                        <p>هذا الرمز صالح لمدة ساعة واحدة فقط. لا تشاركه مع أحد.</p>
                        
                        <div class="footer">
                            برنامج وديعة - كنيسة القديسة رفقة
                        </div>
                    </div>
                </body>
                </html>
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

export const sendWelcomeEmail = async (email: string, name: string) => {
    if (!resend) {
        console.log('\n--- WELCOME EMAIL (MOCK) ---');
        console.log(`To: ${email}`);
        console.log(`Name: ${name}`);
        console.log('----------------------------\n');
        return;
    }

    try {
        await resend.emails.send({
            from: fromEmail,
            to: email,
            subject: 'مرحباً بك في برنامج وديعة!',
            html: `
                <!DOCTYPE html>
                <html dir="rtl" lang="ar">
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; margin: 0; padding: 0; }
                        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #e0e0e0; text-align: right; direction: rtl; }
                        h2 { color: #1a1a1a; margin-top: 0; font-size: 24px; }
                        p { color: #4a4a4a; font-size: 16px; line-height: 1.6; }
                        .welcome-box { background-color: #f0fff4; color: #2e7d32; padding: 20px; border-radius: 8px; margin: 20px 0; border: 1px solid #c8e6c9; }
                        .footer { margin-top: 30px; font-size: 14px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 20px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>مرحباً، ${name}!</h2>
                        
                        <div class="welcome-box">
                            <p style="margin: 0; font-weight: bold; color: #2e7d32;">تم إنشاء حسابك بنجاح!</p>
                        </div>

                        <p>نحن سعداء بانضمامك إلى <strong>برنامج وديعة</strong> الخاص بكنيسة القديسة رفقة بالقناطر الخيرية.</p>
                        <p>حسابك الآن في انتظار التفعيل من قبل المسؤول. سيتم إشعارك فور تفعيله.</p>
                        
                        <br>
                        <p>إذا كان لديك أي أسئلة، لا تتردد في الرد على هذا البريد الإلكتروني.</p>
                        
                        <div class="footer">
                            مع أطيب التحيات،<br>فريق برنامج وديعة
                        </div>
                    </div>
                </body>
                </html>
            `
        });
        console.log(`Welcome email sent to ${email}`);
    } catch (error) {
        console.error('Error sending welcome email:', error);
    }
};
