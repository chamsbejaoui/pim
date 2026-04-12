import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { TestResult, TestResultDocument } from './entities/test-result.entity';
import { CreateTestResultDto } from './dto/create-test-result.dto';
import { UpdateTestResultDto } from './dto/update-test-result.dto';
import { ScoringService } from '../scoring/scoring.service';

@Injectable()
export class TestResultsService {
    constructor(
        @InjectModel(TestResult.name) private testResultModel: Model<TestResultDocument>,
        private scoringService: ScoringService,
    ) { }

    async create(eventPlayerId: string, dto: CreateTestResultDto): Promise<TestResult> {
        // Use ScoringService for intelligent normalization
        const normalizedScore = await this.scoringService.calculateNormalizedScore(
            dto.rawValue,
            dto.testTypeId
        );

        const testResult = new this.testResultModel({
            eventPlayerId: new Types.ObjectId(eventPlayerId),
            testTypeId: new Types.ObjectId(dto.testTypeId),
            rawValue: dto.rawValue,
            normalizedScore,
            notes: dto.notes,
            recordedBy: dto.recordedBy ? new Types.ObjectId(dto.recordedBy) : undefined,
        });

        return testResult.save();
    }

    async findByEventPlayer(eventPlayerId: string): Promise<TestResult[]> {
        const results = await this.testResultModel
            .find({ eventPlayerId: new Types.ObjectId(eventPlayerId) })
            .populate('testTypeId')
            .exec();

        // Safe population for recordedBy
        for (const result of results) {
            if (result.recordedBy && Types.ObjectId.isValid(result.recordedBy.toString())) {
                try {
                    await result.populate('recordedBy', 'firstName lastName');
                } catch (e: any) {
                    console.error(`Failed to populate recordedBy for test result ${result._id}: ${e?.message}`);
                }
            }
        }

        return results;
    }

    async findOne(id: string): Promise<TestResult> {
        const testResult = await this.testResultModel
            .findById(id)
            .populate('testTypeId')
            .exec();

        if (!testResult) {
            throw new NotFoundException(`TestResult with ID ${id} not found`);
        }

        // Safe population for recordedBy
        if (testResult.recordedBy && Types.ObjectId.isValid(testResult.recordedBy.toString())) {
            await testResult.populate('recordedBy', 'firstName lastName');
        }

        return testResult;
    }

    async update(id: string, dto: UpdateTestResultDto): Promise<TestResult> {
        const updateData: any = { ...dto };

        // Si la valeur brute change, recalculer le score (version simplifiée)
        if (dto.rawValue !== undefined) {
            updateData.normalizedScore = Math.min(100, Math.max(0, dto.rawValue));
        }

        const testResult = await this.testResultModel
            .findByIdAndUpdate(id, updateData, { new: true })
            .populate('testTypeId')
            .exec();

        if (!testResult) {
            throw new NotFoundException(`TestResult with ID ${id} not found`);
        }

        // Safe population for recordedBy
        if (testResult.recordedBy && Types.ObjectId.isValid(testResult.recordedBy.toString())) {
            await testResult.populate('recordedBy', 'firstName lastName');
        }

        return testResult;
    }

    async remove(id: string): Promise<void> {
        const result = await this.testResultModel.findByIdAndDelete(id).exec();
        if (!result) {
            throw new NotFoundException(`TestResult with ID ${id} not found`);
        }
    }
}
