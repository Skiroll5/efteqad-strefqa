
import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

let isInitialized = false;

export const initFirebase = async () => {
    try {
        // Check if service account file exists, or use environment variables
        // For this implementation, we'll assume a standard path or environment setup
        // Ideally, user puts 'service-account.json' in server root

        if (!admin.apps.length) {
            // Using default credential (GOOGLE_APPLICATION_CREDENTIALS) or explicit path
            // If running locally, you might need to point to the file
            const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, '../../service-account.json');

            // Note: In production, usually handled by Env vars.
            // We will wrap this in a try-catch to avoid crashing if not set up yet

            let fileContent: string | null = null;
            try {
                fileContent = await fs.promises.readFile(serviceAccountPath, 'utf-8');
            } catch (e) {
                // File not found or not readable
            }

            if (process.env.GOOGLE_APPLICATION_CREDENTIALS || fileContent) {
                let credential;

                if (fileContent) {
                    try {
                        const serviceAccount = JSON.parse(fileContent);
                        credential = admin.credential.cert(serviceAccount);
                    } catch (parseError) {
                         // If JSON parse fails, but we are using ENV var, maybe let standard cert(path) try?
                         // It will likely fail too if file is invalid JSON, but to be safe/consistent:
                         if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
                             credential = admin.credential.cert(serviceAccountPath);
                         } else {
                             throw parseError;
                         }
                    }
                } else {
                     // Env var is set, but we couldn't read file (maybe path is weird, or just not a file path but handled by lib?)
                     // Although admin.credential.cert(path) expects a file path.
                     credential = admin.credential.cert(serviceAccountPath);
                }

                admin.initializeApp({
                    credential,
                });
                isInitialized = true;
                console.log('Firebase Admin initialized successfully');
            } else {
                console.warn('Firebase Service Account not found. Push notifications will NOT be sent.');
            }
        } else {
            isInitialized = true;
        }
    } catch (error) {
        console.error('Failed to initialize Firebase Admin:', error);
    }
};

export const sendDataNotification = async (tokens: string[], title: string, body: string, data?: Record<string, string>) => {
    if (!isInitialized || tokens.length === 0) return;

    try {
        const message: admin.messaging.MulticastMessage = {
            tokens,
            notification: {
                title,
                body,
            },
            data,
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: 'default_channel',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        contentAvailable: true,
                    },
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Sent notification: ${response.successCount} successful, ${response.failureCount} failed`);

        if (response.failureCount > 0) {
            const failedTokens: string[] = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(tokens[idx]);
                    // Potentially remove invalid tokens from DB here
                }
            });
            console.warn('Failed tokens:', failedTokens);
        }
    } catch (error) {
        console.error('Error sending notification:', error);
    }
};
