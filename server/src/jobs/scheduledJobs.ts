
import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';
import { notifyUser } from '../utils/notificationUtils';

const prisma = new PrismaClient();

const checkBirthdays = async (isMorning: boolean) => {
    try {
        console.log(`Running birthday check (${isMorning ? 'Morning' : 'Evening'})...`);

        // Find users who want birthday notifications at this time
        const users = await prisma.user.findMany({
            where: {
                isActive: true,
                isDeleted: false,
                role: { in: ['SERVANT', 'ADMIN'] },
                notificationPreference: {
                    birthdayReminder: true,
                    birthdayNotifyMorning: isMorning
                }
            },
            include: {
                managedClasses: true
            }
        });

        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        // If morning, we look for TODAY's birthdays
        // If evening, we look for TOMORROW's birthdays
        const targetDate = isMorning ? today : tomorrow;
        const targetMonth = targetDate.getMonth() + 1; // 1-12
        const targetDay = targetDate.getDate();

        for (const user of users) {
            // Admin gets all? Or just managed classes?
            // Plan says "Class managers + Admins". 
            // If Admin has no managed classes, maybe they want ALL birthdays? 
            // Let's stick to managed classes for now to avoid spam, unless they are strict Admin.
            // If plan implies Admins get ALL, we might need a separate query.
            // For simplicity/safety: Users get notifications for classes they MANAGE. 
            // Only "New User Registered" is global for Admins.

            const classIds = user.managedClasses.map((cm: any) => cm.classId);
            if (classIds.length === 0) continue;

            // Find students with birthday on target date in these classes
            // Prisma doesn't have great date extraction in where clause for all DBs, 
            // but raw query or fetching all students and filtering in memory works for small scale.
            // Given typical class size, fetching matching month/day roughly is okay or just raw query.
            // Let's use raw query for performance/correctness across years.

            // Postgres specific date function: EXTRACT(MONTH FROM birthdate)
            // We'll use findMany and filter in memory for simplicity if dataset isn't huge, 
            // but raw query is safer for scalability.

            const students = await prisma.$queryRaw`
                SELECT id, name, "classId" FROM students 
                WHERE "isDeleted" = false 
                AND "classId" IN (${Prisma.join(classIds)})
                AND EXTRACT(MONTH FROM birthdate) = ${targetMonth}
                AND EXTRACT(DAY FROM birthdate) = ${targetDay}
             ` as { id: string, name: string, classId: string }[];

            for (const student of students) {
                const title = isMorning ? '🎉 Happy Birthday!' : '🎂 Birthday Tomorrow';
                const body = isMorning
                    ? `Today is ${student.name}'s birthday!`
                    : `${student.name} has a birthday tomorrow!`;

                await notifyUser(user.id, title, body, {
                    type: 'birthday',
                    studentId: student.id
                });
            }
        }

    } catch (error) {
        console.error('Error checking birthdays:', error);
    }
};

const checkInactiveStudents = async () => {
    try {
        console.log('Running inactive student check...');

        // Find users who enabled this
        const users = await prisma.user.findMany({
            where: {
                isActive: true,
                isDeleted: false,
                notificationPreference: {
                    inactiveStudent: true
                }
            },
            include: {
                managedClasses: true,
                notificationPreference: true
            }
        });

        for (const user of users) {
            const classIds = user.managedClasses.map((cm: any) => cm.classId);
            if (classIds.length === 0) continue;

            const thresholdDays = user.notificationPreference?.inactiveThresholdDays || 14;
            const thresholdDate = new Date();
            thresholdDate.setDate(thresholdDate.getDate() - thresholdDays);

            // Find students in these classes who:
            // 1. Have NO attendance records created/updated after thresholdDate
            // 2. OR have never had attendance and were created before thresholdDate?
            // "Inactive" usually means "Attended recently? No."

            // We want students where NOT EXISTS (attendance newer than threshold)
            // Optimized to avoid N+1 query problem

            const inactiveStudents = await prisma.student.findMany({
                where: {
                    classId: { in: classIds },
                    isDeleted: false,
                    attendance: {
                        none: {
                            session: {
                                date: { gte: thresholdDate }
                            }
                        }
                    }
                },
                select: { id: true, name: true }
            });

            for (const student of inactiveStudents) {
                // Check if student is new? If created recently, maybe not inactive?
                // Skipping check for now, assume strict "no attendance in X days"

                await notifyUser(
                    user.id,
                    '⚠️ Check-in Needed',
                    `${student.name} hasn't attended in ${thresholdDays} days`,
                    { type: 'inactive', studentId: student.id }
                );
            }
        }
    } catch (error) {
        console.error('Error checking inactive students:', error);
    }
};

export const initScheduledJobs = () => {
    // 08:00 AM Daily
    cron.schedule('0 8 * * *', () => {
        checkBirthdays(true); // Morning check
        checkInactiveStudents();
    });

    // 08:00 PM Daily
    cron.schedule('0 20 * * *', () => {
        checkBirthdays(false); // Evening check
    });

    console.log('Scheduled jobs initialized');
};

import { Prisma } from '@prisma/client';
