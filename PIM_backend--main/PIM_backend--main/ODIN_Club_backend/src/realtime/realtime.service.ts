import { Injectable, MessageEvent } from '@nestjs/common';
import { interval, merge, Observable, Subject } from 'rxjs';
import { filter, map } from 'rxjs/operators';

export type RealtimeChannel = 'chat' | 'notification';

interface RealtimePayload {
  channel: RealtimeChannel;
  eventType: string;
  clubId: string;
  recipientUserIds: string[];
  payload: Record<string, unknown>;
}

@Injectable()
export class RealtimeService {
  private readonly events$ = new Subject<RealtimePayload>();

  emit(payload: RealtimePayload): void {
    this.events$.next(payload);
  }

  streamForUser(
    channel: RealtimeChannel,
    clubId: string,
    userId: string
  ): Observable<MessageEvent> {
    const stream$ = this.events$.pipe(
      filter(
        (event) =>
          event.channel === channel &&
          event.clubId === clubId &&
          event.recipientUserIds.includes(userId)
      ),
      map((event) => ({
        data: {
          channel: event.channel,
          eventType: event.eventType,
          payload: event.payload,
          emittedAt: new Date().toISOString()
        }
      }))
    );

    const heartbeat$ = interval(25000).pipe(
      map(() => ({
        data: {
          channel,
          eventType: 'heartbeat',
          payload: {},
          emittedAt: new Date().toISOString()
        }
      }))
    );

    return merge(stream$, heartbeat$);
  }
}
