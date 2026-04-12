import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PayrollRunDocument = HydratedDocument<PayrollRun>;

@Schema({ collection: 'payroll_runs', timestamps: true })
export class PayrollRun {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ required: true })
  periodStart: Date;

  @Prop({ required: true })
  periodEnd: Date;

  @Prop({ required: true })
  totalAmount: number;

  @Prop({ default: 'PREVIEW', index: true })
  status: 'PREVIEW' | 'EXECUTED' | 'PAID';

  @Prop({ type: Array, default: [] })
  lines: Array<Record<string, unknown>>;
}

export const PayrollRunSchema = SchemaFactory.createForClass(PayrollRun);
PayrollRunSchema.index({ clubId: 1, periodStart: -1, periodEnd: -1 });
