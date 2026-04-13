import { calculateNotificationExpiry } from './retention.util';

describe('calculateNotificationExpiry', () => {
  it('adds exactly 20 days to readAt', () => {
    const readAt = new Date('2026-02-01T10:30:00.000Z');
    const expiresAt = calculateNotificationExpiry(readAt);

    expect(expiresAt.toISOString()).toBe('2026-02-21T10:30:00.000Z');
  });
});
