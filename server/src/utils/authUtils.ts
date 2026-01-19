import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get all class IDs that the user manages.
 * @param userId The ID of the user.
 * @returns A list of class IDs.
 */
export const getUserManagedClassIds = async (userId: string): Promise<string[]> => {
    const managers = await prisma.classManager.findMany({
        where: { userId, isDeleted: false },
        select: { classId: true }
    });
    return managers.map(m => m.classId);
};

/**
 * Check if a user is a manager of a specific class.
 * @param userId The ID of the user.
 * @param classId The ID of the class.
 * @returns True if the user is a manager, false otherwise.
 */
export const isClassManager = async (userId: string, classId: string): Promise<boolean> => {
    const manager = await prisma.classManager.findUnique({
        where: {
            classId_userId: {
                classId,
                userId
            }
        }
    });
    return !!manager && !manager.isDeleted;
};
