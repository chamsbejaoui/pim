import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { PredictPlayerDto } from './dto/predict-player.dto';
import { TrainPlayerDto } from './dto/train-player.dto';

@Injectable()
export class AiService {
    private readonly logger = new Logger(AiService.name);
    private readonly aiBaseUrl: string;

    constructor(
        private readonly httpService: HttpService,
        private readonly configService: ConfigService,
    ) {
        this.aiBaseUrl =
            this.configService.get<string>('AI_SERVICE_URL') ||
            'http://localhost:8000';
        this.logger.log(`AI Service URL: ${this.aiBaseUrl}`);
    }

    /**
     * Predict recruitment decision for a player.
     * Calls Python: POST /predict
     */
    async predict(dto: PredictPlayerDto): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.post(`${this.aiBaseUrl}/predict`, dto),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'predict');
        }
    }

    /**
     * Send labeled players for training.
     * Calls Python: POST /train
     */
    async train(players: TrainPlayerDto[]): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.post(`${this.aiBaseUrl}/train`, players),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'train');
        }
    }

    /**
     * Get the training dataset.
     * Calls Python: GET /dataset
     */
    async getDataset(): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.get(`${this.aiBaseUrl}/dataset`),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'dataset');
        }
    }

    /**
     * Get model metrics (cross-validation, feature importance, etc.).
     * Calls Python: GET /metrics
     */
    async getMetrics(): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.get(`${this.aiBaseUrl}/metrics`),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'metrics');
        }
    }

    /**
     * Find similar players from the training dataset.
     * Calls Python: POST /similar
     */
    async findSimilar(dto: PredictPlayerDto, topN: number = 5): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.post(`${this.aiBaseUrl}/similar?top_n=${topN}`, dto),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'similar');
        }
    }

    /**
     * Compute development potential score.
     * Calls Python: POST /potential
     */
    async getPotential(dto: PredictPlayerDto): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.post(`${this.aiBaseUrl}/potential`, dto),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'potential');
        }
    }

    /**
     * Generate personalized development plan.
     * Calls Python: POST /development-plan
     */
    async getDevelopmentPlan(dto: PredictPlayerDto): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.post(`${this.aiBaseUrl}/development-plan`, dto),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'development-plan');
        }
    }

    /**
     * Get model status (trained, dataset size, etc.).
     * Calls Python: GET /status
     */
    async getStatus(): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.get(`${this.aiBaseUrl}/status`),
            );
            return response.data;
        } catch (error) {
            this.handleAiError(error, 'status');
        }
    }

    /**
     * Health check — verify the Python AI service is reachable.
     */
    async healthCheck(): Promise<any> {
        try {
            const response = await firstValueFrom(
                this.httpService.get(`${this.aiBaseUrl}/`),
            );
            return {
                ai_service: 'online',
                message: response.data?.message || 'Connected',
            };
        } catch (error) {
            return {
                ai_service: 'offline',
                message: `Cannot reach AI service at ${this.aiBaseUrl}`,
            };
        }
    }

    private handleAiError(error: any, endpoint: string): never {
        const status =
            error.response?.status || HttpStatus.SERVICE_UNAVAILABLE;
        const message =
            error.response?.data?.detail ||
            error.message ||
            `AI service error on /${endpoint}`;

        this.logger.error(
            `AI Service error [${endpoint}]: ${message}`,
            error.stack,
        );

        throw new HttpException(
            {
                error: `AI Service error`,
                endpoint: `/${endpoint}`,
                detail: message,
            },
            status,
        );
    }
}
