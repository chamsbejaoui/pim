import { Module } from '@nestjs/common';
import { EventsModule } from './events/events.module';
import { TestTypesModule } from './test-types/test-types.module';
import { EventPlayersModule } from './event-players/event-players.module';
import { TestResultsModule } from './test-results/test-results.module';
import { ScoringModule } from './scoring/scoring.module';
import { ReportsModule } from './reports/reports.module';
import { ExercisesModule } from './exercises/exercises.module';
import { CognitiveLabModule } from './cognitive-lab/cognitive-lab.module';
import { NutritionLabModule } from './nutrition-lab/nutrition-lab.module';

@Module({
    imports: [
        EventsModule,
        TestTypesModule,
        EventPlayersModule,
        TestResultsModule,
        ScoringModule,
        ReportsModule,
        ExercisesModule,
        CognitiveLabModule,
        NutritionLabModule,
    ],
    exports: [
        EventsModule,
        TestTypesModule,
        EventPlayersModule,
        TestResultsModule,
        ScoringModule,
        ReportsModule,
        ExercisesModule,
        CognitiveLabModule,
        NutritionLabModule,
    ],
})
export class SportsPerformanceModule { }
