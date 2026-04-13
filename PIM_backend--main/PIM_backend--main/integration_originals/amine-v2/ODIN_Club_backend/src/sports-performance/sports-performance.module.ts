import { Module } from '@nestjs/common';
import { PlayersModule } from './players/players.module';
import { EventsModule } from './events/events.module';
import { TestTypesModule } from './test-types/test-types.module';
import { EventPlayersModule } from './event-players/event-players.module';
import { TestResultsModule } from './test-results/test-results.module';
import { ScoringModule } from './scoring/scoring.module';
import { ReportsModule } from './reports/reports.module';

@Module({
    imports: [
        PlayersModule,
        EventsModule,
        TestTypesModule,
        EventPlayersModule,
        TestResultsModule,
        ScoringModule,
        ReportsModule,
    ],
    exports: [
        PlayersModule,
        EventsModule,
        TestTypesModule,
        EventPlayersModule,
        TestResultsModule,
        ScoringModule,
        ReportsModule,
    ],
})
export class SportsPerformanceModule { }

