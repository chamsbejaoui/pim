import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EventsService } from './events.service';
import { EventsController } from './events.controller';
import { Event, EventSchema } from './entities/event.entity';
import { EventPlayer, EventPlayerSchema } from '../event-players/entities/event-player.entity';
import { TestResult, TestResultSchema } from '../test-results/entities/test-result.entity';
import { AiModule } from '../../ai/ai.module';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: Event.name, schema: EventSchema },
            { name: EventPlayer.name, schema: EventPlayerSchema },
            { name: TestResult.name, schema: TestResultSchema },
        ]),
        AiModule,
    ],
    controllers: [EventsController],
    providers: [EventsService],
    exports: [EventsService],
})
export class EventsModule { }
