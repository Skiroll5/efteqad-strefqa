
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/authMiddleware';

const prisma = new PrismaClient();

export const syncChanges = async (req: AuthRequest, res: Response) => {
    if (req.method === 'POST') {
        return handlePush(req, res);
    } else if (req.method === 'GET') {
        return handlePull(req, res);
    } else {
        return res.sendStatus(405);
    }
};

const handlePush = async (req: AuthRequest, res: Response) => {
    const { changes } = req.body;
    console.log('SyncController: Received push request', JSON.stringify(req.body, null, 2));
    if (!Array.isArray(changes)) return res.status(400).json({ message: 'Invalid format' });

    // Sort changes by dependency order: CLASS -> USER/STUDENT -> ATTENDANCE/NOTE
    const priority = { 'CLASS': 1, 'USER': 2, 'STUDENT': 3, 'ATTENDANCE': 4, 'NOTE': 4 };

    changes.sort((a: any, b: any) => {
        const pA = priority[a.entityType as keyof typeof priority] || 99;
        const pB = priority[b.entityType as keyof typeof priority] || 99;
        return pA - pB;
    });

    const processedUuids: string[] = [];
    const failedUuids: { uuid: string; error: string }[] = [];

    // Process sequentially to maintain order
    for (const change of changes) {
        const { uuid, entityType, entityId, operation, payload, createdAt } = change;

        // Idempotency Check: Ideally we should track processed UUIDs in a specialized table
        // For now, we rely on Last-Write-Wins based on logic below or standard upserts
        // BUT, a robust system *should* have a 'ProcessedSync' table. 
        // Let's implement a simple version where we assume 'uuid' is unique for the operation 
        // and if we successfully process it, we are good.
        // If the client retries, we might re-process. For "Last Write Wins", re-processing is usually fine 
        // as long as timestamps are respected.

        const modelName = mapEntityToModel(entityType);
        if (!modelName) {
            console.warn(`Unknown entity type: ${entityType}`);
            failedUuids.push({ uuid, error: `Unknown entity type: ${entityType}` });
            continue;
        }

        try {
            const dbModel = (prisma as any)[modelName];

            if (operation === 'VIRTUAL_DELETE' || operation === 'DELETE') {
                // If client sends DELETE, we just want to ensure it's marked deleted.
                // We use updateMany to avoid "Record to update not found" errors (P2025)
                // and to avoid 'upsert' trying to CREATE a record with missing required fields (the error user saw).

                const deleteData: any = {
                    isDeleted: true,
                    deletedAt: payload.deletedAt ? new Date(payload.deletedAt) : new Date(),
                    updatedAt: new Date() // Always bump update time
                };

                await dbModel.updateMany({
                    where: { id: entityId },
                    data: deleteData
                });
            } else {
                // CREATE or UPDATE
                // Remove ID from payload if present to avoid "Argument id for data.id must not be null" if it conflicts?
                // Prisma upsert needs where.

                // Payload should match Prisma schema. 
                // Client sends dates as strings, need to ensure proper parsing if not handled by Prisma auto-mapping?
                // Prisma maps ISO strings to Date automatically usually.

                const sanitizedPayload = sanitizePayload(payload);

                await dbModel.upsert({
                    where: { id: entityId },
                    create: { ...sanitizedPayload, id: entityId },
                    update: { ...sanitizedPayload },
                });
            }
            processedUuids.push(uuid);
        } catch (e: any) {
            console.error(`Sync error for ${uuid}:`, e);
            failedUuids.push({ uuid, error: e.message || String(e) });
            // Continue to process other items even if one fails
        }
    }

    res.json({ success: true, processedUuids, failedUuids });
};

const sanitizePayload = (payload: any) => {
    const newPayload = { ...payload };
    for (const key in newPayload) {
        let value = newPayload[key];
        if (typeof value === 'string') {
            // Check if it looks like a date (basic ISO check or specific field names)
            if (key.endsWith('At') || key === 'date' || key === 'birthdate') {
                // Dart sends microseconds (6 digits), JS Date supports milliseconds (3 digits).
                // We trim the microseconds to milliseconds if present.
                if (/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}/.test(value)) {
                    // Keep only first 3 fractional digits
                    value = value.replace(/(\.\d{3})\d+/, '$1');
                }
                // If it's a valid date string, convert to Date object
                const date = new Date(value);
                if (!isNaN(date.getTime())) {
                    newPayload[key] = date;
                }
                // If invalid, we leave it as string (Prisma might throw, but better than silent fail)
            }
        }
    }
    return newPayload;
};

const handlePull = async (req: AuthRequest, res: Response) => {
    const since = req.query.since as string;
    const sinceDate = since ? new Date(since) : new Date(0);

    const serverTimestamp = new Date().toISOString();

    // Fetch changes
    const students = await prisma.student.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const attendance = await prisma.attendanceRecord.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const notes = await prisma.note.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    const classes = await prisma.class.findMany({
        where: { updatedAt: { gt: sinceDate } },
    });

    res.json({
        serverTimestamp,
        changes: {
            students,
            attendance,
            notes,
            classes,
        },
    });
};

const mapEntityToModel = (type: string): string | null => {
    switch (type) {
        case 'STUDENT': return 'student';
        case 'ATTENDANCE': return 'attendanceRecord';
        case 'NOTE': return 'note';
        case 'CLASS': return 'class';
        default: return null;
    }
};
