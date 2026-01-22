import { getIO } from '../socket';

export type RealtimeNotificationLevel = 'info' | 'success' | 'warning' | 'error';
export type RealtimeNotificationAudience = 'all' | 'admins' | 'user';

export interface RealtimeNotificationPayload {
    level: RealtimeNotificationLevel;
    title: string;
    message: string;
    audience?: RealtimeNotificationAudience;
    targetUserId?: string;
    entityType?: string;
    entityId?: string;
    classId?: string;
}

export const emitAppNotification = (payload: RealtimeNotificationPayload) => {
    const io = getIO();
    const audience = payload.audience || 'all';

    if (audience === 'admins') {
        // Emitting to 'admins' room. Clients must join this room.
        io.to('admins').emit('app_notification', payload);
    } else if (audience === 'user' && payload.targetUserId) {
        // Emitting to user-specific room 'user_<userId>'. Clients must join this room.
        io.to(`user_${payload.targetUserId}`).emit('app_notification', payload);
    } else if (audience === 'all') {
        io.emit('app_notification', payload);
    } else {
        console.warn('Unknown audience or missing targetUserId for notification:', payload);
    }
};
