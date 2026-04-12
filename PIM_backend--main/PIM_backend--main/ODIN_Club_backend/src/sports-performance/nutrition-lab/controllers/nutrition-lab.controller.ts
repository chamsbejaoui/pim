import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { NutritionLabService } from '../services/nutrition-lab.service';
import { MetabolicAiService } from '../services/metabolic-ai.service';
import { CreatePhysicalProfileDto } from '../dto/create-physical-profile.dto';
import { LogNutritionDto } from '../dto/log-nutrition.dto';

@Controller('sports-performance/nutrition-lab')
export class NutritionLabController {
  constructor(
    private nutritionService: NutritionLabService,
    private metabolicService: MetabolicAiService
  ) {}

  @Post('profile/:userId')
  async createOrUpdateProfile(
    @Param('userId') userId: string,
    @Body() dto: CreatePhysicalProfileDto
  ) {
    // Override the user ID just in case
    dto.userId = userId;
    return this.nutritionService.createOrUpdatePhysicalProfile(userId, dto);
  }

  @Get('profile/:userId')
  async getProfile(@Param('userId') userId: string) {
    return this.nutritionService.getPhysicalProfile(userId);
  }

  @Post('log')
  async logNutrition(@Body() dto: LogNutritionDto) {
    return this.nutritionService.logNutrition(dto);
  }

  @Get('metabolic-status/:userId')
  async getMetabolicStatus(@Param('userId') userId: string) {
    return this.metabolicService.getDailyMetabolicStatus(userId);
  }

  @Get('weekly-plan/:userId')
  async getWeeklyPlan(@Param('userId') userId: string) {
    return this.nutritionService.getWeeklyMealPlan(userId);
  }

  @Post('weekly-plan/generate/:userId')
  async generateAiWeeklyPlan(@Param('userId') userId: string) {
    // Dans cette version, nous utilisons le service pour retourner un plan "généré"
    // On pourrait ici ajouter une logique de sauvegarde en DB si besoin.
    return this.nutritionService.getWeeklyMealPlan(userId);
  }
}
