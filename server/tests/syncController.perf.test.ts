
import { PrismaClient } from '@prisma/client';
import { mockDeep } from 'jest-mock-extended';
import { Request, Response } from 'express';
import { AuthRequest } from '../src/middleware/authMiddleware';

const mockPrisma = mockDeep<PrismaClient>();

jest.mock('@prisma/client', () => ({
    PrismaClient: jest.fn(() => mockPrisma)
}));

jest.mock('../src/utils/notificationUtils', () => ({
    notifyClassManagers: jest.fn().mockResolvedValue(undefined)
}));

// Use require to ensure mock is set up before controller is imported
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { syncChanges } = require('../src/controllers/syncController');

describe('SyncController Performance', () => {
    let req: Partial<AuthRequest>;
    let res: Partial<Response>;
    let jsonMock: jest.Mock;

    beforeEach(() => {
        jest.clearAllMocks();
        jsonMock = jest.fn();
        res = {
            status: jest.fn().mockReturnThis(),
            json: jsonMock,
            sendStatus: jest.fn(),
        };
        (mockPrisma.$transaction as jest.Mock).mockImplementation((promises) => Promise.all(promises));
        (mockPrisma as any).note = { upsert: jest.fn() };
        (mockPrisma as any).attendanceSession = { upsert: jest.fn() };
        (mockPrisma as any).student = { findUnique: jest.fn(), findMany: jest.fn() };
        (mockPrisma as any).user = { findUnique: jest.fn(), findMany: jest.fn() };
        (mockPrisma as any).class = { findUnique: jest.fn(), findMany: jest.fn() };
    });

    it('should demonstrate N+1 queries behavior', async () => {
        const changes: any[] = [];
        const numChanges = 10;

        // Add NOTE changes
        for (let i = 0; i < numChanges; i++) {
            changes.push({
                uuid: `uuid-note-${i}`,
                entityType: 'NOTE',
                operation: 'CREATE',
                entityId: `note-${i}`,
                payload: { studentId: `student-${i}`, content: 'test', updatedAt: new Date() }
            });
        }

        req = {
            method: 'POST',
            body: { changes },
            user: { userId: 'author-1', role: 'USER' },
            app: { get: jest.fn() } as any
        };

        // Mock FindUnique for Student and User (Author)
        // With optimization, these findUnique should NOT be called
        (mockPrisma.student.findUnique as jest.Mock).mockResolvedValue({ id: 'student-1', classId: 'class-1', name: 'Student' });
        (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'author-1', name: 'Author' });

        // Mock FindMany
        (mockPrisma.student.findMany as jest.Mock).mockResolvedValue(
            Array.from({ length: numChanges }, (_, i) => ({ id: `student-${i}`, classId: 'class-1', name: `Student ${i}` }))
        );
        (mockPrisma.class.findMany as jest.Mock).mockResolvedValue([]);

        await syncChanges(req as AuthRequest, res as Response);

        // Wait for background process ("fire and forget")
        await new Promise(r => setTimeout(r, 100));

        const studentFindUniqueCalls = (mockPrisma.student.findUnique as jest.Mock).mock.calls.length;
        const userFindUniqueCalls = (mockPrisma.user.findUnique as jest.Mock).mock.calls.length;

        const studentFindManyCalls = (mockPrisma.student.findMany as jest.Mock).mock.calls.length;
        const classFindManyCalls = (mockPrisma.class.findMany as jest.Mock).mock.calls.length;

        console.log(`Student findUnique calls: ${studentFindUniqueCalls}`);
        console.log(`User findUnique calls: ${userFindUniqueCalls}`);
        console.log(`Student findMany calls: ${studentFindManyCalls}`);

        // Expectations after optimization:
        // No findUnique calls for student in the loop
        expect(studentFindUniqueCalls).toBe(0);

        // User (author) fetched once
        expect(userFindUniqueCalls).toBe(1);

        // Students bulk fetched once
        expect(studentFindManyCalls).toBe(1);

    });
});
