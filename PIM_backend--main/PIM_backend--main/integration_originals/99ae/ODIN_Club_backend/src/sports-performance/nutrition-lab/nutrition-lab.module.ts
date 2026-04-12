import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NutritionLabController } from './controllers/nutrition-lab.controller';
import { NutritionLabService } from './services/nutrition-lab.service';
import { MetabolicAiService } from './services/metabolic-ai.service';
import { PhysicalProfile, PhysicalProfileSchema } from './entities/physical-profile.entity';
import { NutritionLog, NutritionLogSchema } from './entities/nutrition-log.entity';
import { CognitiveLabModule } from '../cognitive-lab/cognitive-lab.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PhysicalProfile.name, schema: PhysicalProfileSchema },
      { name: NutritionLog.name, schema: NutritionLogSchema }
    ]),
    CognitiveLabModule
  ],
  controllers: [NutritionLabController],
  providers: [NutritionLabService, MetabolicAiService],
  exports: [NutritionLabService, MetabolicAiService]
})
export class NutritionLabModule {}
