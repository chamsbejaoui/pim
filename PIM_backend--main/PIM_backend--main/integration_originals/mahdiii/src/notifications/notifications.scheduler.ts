import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Injectable()
export class NotificationsScheduler implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationsScheduler.name);
  private timer: NodeJS.Timeout | null = null;
  private lastCleanupKey = '';

  constructor(private readonly notificationsService: NotificationsService) {}

  onModuleInit() {
    this.timer = setInterval(() => {
      void this.tick();
    }, 60 * 1000);

    void this.tick();
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  private async tick() {
    const now = new Date();

    try {
      await this.notificationsService.dispatchDueTrainingReminders(now);
    } catch (error) {
      this.logger.error('Failed to dispatch training reminders', error as Error);
    }

    const cleanupKey = `${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
    const isCleanupWindow = now.getHours() === 3;
    if (!isCleanupWindow || this.lastCleanupKey === cleanupKey) {
      return;
    }

    try {
      await this.notificationsService.cleanupExpiredNotifications(now);
      this.lastCleanupKey = cleanupKey;
    } catch (error) {
      this.logger.error('Failed to cleanup notifications', error as Error);
    }
  }
}
