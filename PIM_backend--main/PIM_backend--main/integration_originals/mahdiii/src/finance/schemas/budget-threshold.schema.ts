import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type BudgetThresholdDocument = HydratedDocument<BudgetThreshold>;

@Schema({ _id: false })
export class BudgetItem {
  @Prop({ required: true })
  category: string;

  @Prop({ required: true })
  threshold: number;

  @Prop({ required: true, default: 0 })
  utilized: number;
}

@Schema({ collection: 'budget_thresholds', timestamps: true })
export class BudgetThreshold {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, unique: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: [BudgetItem], default: [] })
  items: BudgetItem[];
}

export const BudgetThresholdSchema = SchemaFactory.createForClass(BudgetThreshold);
