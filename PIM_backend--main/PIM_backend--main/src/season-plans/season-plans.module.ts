import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SeasonPlansController } from './season-plans.controller';
import { SeasonPlansService } from './season-plans.service';
import { SeasonPlan, SeasonPlanSchema } from './schemas/season-plan.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: SeasonPlan.name, schema: SeasonPlanSchema }]),
  ],
  controllers: [SeasonPlansController],
  providers: [SeasonPlansService],
  exports: [SeasonPlansService],
})
export class SeasonPlansModule {}
