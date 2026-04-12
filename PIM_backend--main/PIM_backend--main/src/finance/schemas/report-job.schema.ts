import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ReportJobDocument = HydratedDocument<ReportJob>;

@Schema({ collection: 'report_jobs', timestamps: true })
export class ReportJob {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requestedByUserId: Types.ObjectId;

  @Prop({ required: true })
  type: string;

  @Prop({ default: 'DONE', index: true })
  status: 'PENDING' | 'DONE' | 'FAILED';

  @Prop({ required: true })
  fileContent: string;

  createdAt: Date;
}

export const ReportJobSchema = SchemaFactory.createForClass(ReportJob);
ReportJobSchema.index({ clubId: 1, createdAt: -1 });
