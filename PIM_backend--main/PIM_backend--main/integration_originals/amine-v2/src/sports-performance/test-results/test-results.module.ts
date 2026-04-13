import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TestResultsService } from './test-results.service';
import {
    TestResultsController,
    TestResultsManagementController,
} from './test-results.controller';
import { TestResult, TestResultSchema } from './entities/test-result.entity';
import { ScoringModule } from '../scoring/scoring.module';

@Module({
    imports: [
        MongooseModule.forFeature([{ name: TestResult.name, schema: TestResultSchema }]),
        ScoringModule,
    ],
    controllers: [TestResultsController, TestResultsManagementController],
    providers: [TestResultsService],
    exports: [TestResultsService],
})
export class TestResultsModule { }
