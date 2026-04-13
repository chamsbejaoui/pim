import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type LedgerEntryDocument = HydratedDocument<LedgerEntry>;

@Schema({ collection: 'ledger_entries', timestamps: true })
export class LedgerEntry {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ required: true })
  entryDate: Date;

  @Prop({ required: true, index: true })
  type: string;

  @Prop({ required: true })
  description: string;

  @Prop({ required: true })
  amount: number;

  @Prop({ default: 'DRAFT', index: true })
  status: 'DRAFT' | 'POSTED';
}

export const LedgerEntrySchema = SchemaFactory.createForClass(LedgerEntry);
LedgerEntrySchema.index({ clubId: 1, entryDate: -1, type: 1 });
