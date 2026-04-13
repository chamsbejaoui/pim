import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ReportsService } from './reports.service';
import { ReportsController } from './reports.controller';
import { EventReport, EventReportSchema } from './entities/event-report.entity';
import { PlayerReport, PlayerReportSchema } from './entities/player-report.entity';
import { Event, EventSchema } from '../events/entities/event.entity';
import { EventPlayer, EventPlayerSchema } from '../event-players/entities/event-player.entity';
import { TestResult, TestResultSchema } from '../test-results/entities/test-result.entity';
import { TestType, TestTypeSchema } from '../test-types/entities/test-type.entity';
import { ScoringModule } from '../scoring/scoring.module';
import { PlayersModule } from '../../players/players.module';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: EventReport.name, schema: EventReportSchema },
            { name: PlayerReport.name, schema: PlayerReportSchema },
            { name: Event.name, schema: EventSchema },
            { name: EventPlayer.name, schema: EventPlayerSchema },
            { name: TestResult.name, schema: TestResultSchema },
            { name: TestType.name, schema: TestTypeSchema },
        ]),
        ScoringModule,
        PlayersModule,
    ],
    controllers: [ReportsController],
    providers: [ReportsService],
    exports: [ReportsService],
})
export class ReportsModule { }
