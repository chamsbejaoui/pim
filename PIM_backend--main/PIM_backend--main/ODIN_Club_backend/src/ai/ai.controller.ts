import { Controller, Get, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AiService } from './ai.service';
import { PredictPlayerDto } from './dto/predict-player.dto';
import { TrainPlayerDto } from './dto/train-player.dto';

@ApiTags('ai')
@Controller('ai')
export class AiController {
    constructor(private readonly aiService: AiService) { }

    @Get('health')
    @ApiOperation({ summary: 'Check if the Python AI service is online' })
    @ApiResponse({ status: 200, description: 'AI service health status' })
    healthCheck() {
        return this.aiService.healthCheck();
    }

    @Post('predict')
    @ApiOperation({
        summary: 'Predict recruitment decision for a user player profile',
        description:
            'Sends user-linked player stats to the AI model and returns recruitment decision, ' +
            'confidence score, cluster profile, and SHAP feature explanation.',
    })
    @ApiResponse({
        status: 200,
        description: 'Prediction with SHAP explanation and calibrated confidence',
    })
    @ApiResponse({
        status: 503,
        description: 'AI service unavailable',
    })
    predict(@Body() dto: PredictPlayerDto) {
        return this.aiService.predict(dto);
    }

    @Post('train')
    @ApiOperation({
        summary: 'Send labeled user player profiles for model training',
        description:
            'Sends an array of labeled user player profiles to the AI model. ' +
            'The model retrains with cross-validation, calibration, and clustering.',
    })
    @ApiResponse({
        status: 200,
        description: 'Training results with metrics',
    })
    train(@Body() users: TrainPlayerDto[]) {
        return this.aiService.train(users);
    }

    @Get('dataset')
    @ApiOperation({ summary: 'Get the AI training dataset' })
    @ApiResponse({
        status: 200,
        description: 'Current training dataset stored in the AI service',
    })
    getDataset() {
        return this.aiService.getDataset();
    }

    @Post('similar')
    @ApiOperation({
        summary: 'Find similar user player profiles from the training dataset',
        description: 'Uses Euclidean distance in scaled feature space to find the N most similar profiles.',
    })
    @ApiResponse({ status: 200, description: 'List of similar profiles with similarity scores' })
    findSimilar(@Body() dto: PredictPlayerDto) {
        return this.aiService.findSimilar(dto);
    }

    @Post('potential')
    @ApiOperation({
        summary: 'Compute development potential score',
        description: 'Age-weighted score (0-100) based on proximity to the Elite cluster centroid.',
    })
    @ApiResponse({ status: 200, description: 'Potential score with Elite gap breakdown' })
    getPotential(@Body() dto: PredictPlayerDto) {
        return this.aiService.getPotential(dto);
    }

    @Post('development-plan')
    @ApiOperation({
        summary: 'Generate personalized development plan',
        description: 'SHAP-based analysis of weaknesses with improvement targets towards Elite level.',
    })
    @ApiResponse({ status: 200, description: 'Improvement plan with strengths and weaknesses' })
    getDevelopmentPlan(@Body() dto: PredictPlayerDto) {
        return this.aiService.getDevelopmentPlan(dto);
    }

    @Get('metrics')
    @ApiOperation({
        summary: 'Get model metrics',
        description:
            'Returns cross-validation metrics, feature importance, calibration info, and clustering details.',
    })
    @ApiResponse({ status: 200, description: 'Model metrics' })
    getMetrics() {
        return this.aiService.getMetrics();
    }

    @Get('status')
    @ApiOperation({
        summary: 'Get model status',
        description:
            'Check if the AI model is trained, dataset size, number of labeled samples, etc.',
    })
    @ApiResponse({ status: 200, description: 'Model status' })
    getStatus() {
        return this.aiService.getStatus();
    }
}
