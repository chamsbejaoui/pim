import { Injectable, NotFoundException, Logger, Inject, forwardRef } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Exercise, ExerciseDocument } from './entities/exercise.entity';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { ExercisesAiService } from './exercises-ai.service';

@Injectable()
export class ExercisesService {
    private readonly logger = new Logger(ExercisesService.name);

    constructor(
        @InjectModel(Exercise.name) private exerciseModel: Model<ExerciseDocument>,
        private readonly aiService: ExercisesAiService,
    ) { }

    async generateAndSaveAiDrill(context: any): Promise<ExerciseDocument> {
        const aiDrill = await this.aiService.generateDrill(context);

        // Map the AI response to our schema
        // OpenAI returns 'technicalDetails', Mock returns 'technicalData'
        const drillData = {
            ...aiDrill,
            technicalData: aiDrill.technicalDetails || aiDrill.technicalData,
        };

        const createdDrill = new this.exerciseModel(drillData);
        return createdDrill.save();
    }

    async create(createExerciseDto: CreateExerciseDto): Promise<ExerciseDocument> {
        const createdExercise = new this.exerciseModel(createExerciseDto);
        return createdExercise.save();
    }

    async findAll(query: any = {}): Promise<ExerciseDocument[]> {
        return this.exerciseModel.find(query).exec();
    }

    async findOne(id: string): Promise<ExerciseDocument> {
        const exercise = await this.exerciseModel.findById(id).exec();
        if (!exercise) {
            throw new NotFoundException(`Exercise with ID ${id} not found`);
        }
        return exercise;
    }

    async update(id: string, updateExerciseDto: UpdateExerciseDto): Promise<ExerciseDocument> {
        const updatedExercise = await this.exerciseModel
            .findByIdAndUpdate(id, updateExerciseDto, { new: true })
            .exec();
        if (!updatedExercise) {
            throw new NotFoundException(`Exercise with ID ${id} not found`);
        }
        return updatedExercise;
    }

    async remove(id: string): Promise<any> {
        const result = await this.exerciseModel.findByIdAndDelete(id).exec();
        if (!result) {
            throw new NotFoundException(`Exercise with ID ${id} not found`);
        }
        return { deleted: true };
    }

    /**
     * AI Adaptive Difficulty Logic
     * Si PerformanceRatio > 1.2 -> difficulty++
     * Si PerformanceRatio < 0.8 -> difficulty--
     */
    async adaptDifficulty(id: string, performanceRatio: number): Promise<ExerciseDocument> {
        const exercise = await this.findOne(id);
        let newDifficulty = exercise.difficulty;

        if (performanceRatio > 1.2 && newDifficulty < 5) {
            newDifficulty++;
            this.logger.log(`Increased difficulty for exercise ${exercise.name} (Ratio: ${performanceRatio})`);
        } else if (performanceRatio < 0.8 && newDifficulty > 1) {
            newDifficulty--;
            this.logger.log(`Decreased difficulty for exercise ${exercise.name} (Ratio: ${performanceRatio})`);
        }

        if (newDifficulty !== exercise.difficulty) {
            return this.update(id, { difficulty: newDifficulty });
        }

        return exercise;
    }

    async getPlayerInsights(playerId: string): Promise<any> {
        return this.aiService.getPlayerInsights(playerId);
    }

    async recordCompletion(id: string, session: { playerId: string; durationSeconds: number; lapsCount: number }): Promise<any> {
        const exercise = await this.findOne(id);
        const sessionRecord = {
            playerId: session.playerId,
            completedAt: new Date(),
            durationSeconds: session.durationSeconds,
            lapsCount: session.lapsCount,
        };

        // Push the session to a completedSessions array on the exercise document
        const updated = await this.exerciseModel.findByIdAndUpdate(
            id,
            { $push: { completedSessions: sessionRecord } },
            { new: true }
        ).exec();

        this.logger.log(`Exercise "${exercise.name}" completed by player ${session.playerId} in ${session.durationSeconds}s`);
        return { success: true, session: sessionRecord };
    }
}
