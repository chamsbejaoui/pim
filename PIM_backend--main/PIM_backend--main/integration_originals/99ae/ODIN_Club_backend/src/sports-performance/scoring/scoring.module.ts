import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ScoringService } from './scoring.service';
import { TestType, TestTypeSchema } from '../test-types/entities/test-type.entity';

@Module({
    imports: [
        MongooseModule.forFeature([{ name: TestType.name, schema: TestTypeSchema }]),
    ],
    providers: [ScoringService],
    exports: [ScoringService],
})
export class ScoringModule { }
