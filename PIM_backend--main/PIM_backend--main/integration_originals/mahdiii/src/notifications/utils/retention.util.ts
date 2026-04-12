const TWENTY_DAYS_MS = 20 * 24 * 60 * 60 * 1000;

export function calculateNotificationExpiry(readAt: Date): Date {
  return new Date(readAt.getTime() + TWENTY_DAYS_MS);
}
