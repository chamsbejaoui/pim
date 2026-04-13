import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ExercisesService } from './exercises.service';
import { ExercisesAiService } from './exercises-ai.service';
import { ExercisesController } from './exercises.controller';
import { Exercise, ExerciseSchema } from './entities/exercise.entity';
import { TestResult, TestResultSchema } from '../test-results/entities/test-result.entity';
import { TestType, TestTypeSchema } from '../test-types/entities/test-type.entity';
import { Event, EventSchema } from '../events/entities/event.entity';
import { EventPlayer, EventPlayerSchema } from '../event-players/entities/event-player.entity';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: Exercise.name, schema: ExerciseSchema },
            { name: TestResult.name, schema: TestResultSchema },
            { name: TestType.name, schema: TestTypeSchema },
            { name: Event.name, schema: EventSchema },
            { name: EventPlayer.name, schema: EventPlayerSchema },
        ]),
        HttpModule,
    ],
    controllers: [ExercisesController],
    providers: [ExercisesService, ExercisesAiService],
    exports: [ExercisesService, ExercisesAiService],
})
export class ExercisesModule { }
