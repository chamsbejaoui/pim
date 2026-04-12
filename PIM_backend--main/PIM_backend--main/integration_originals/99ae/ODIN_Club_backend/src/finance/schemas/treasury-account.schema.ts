import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type TreasuryAccountDocument = HydratedDocument<TreasuryAccount>;

@Schema({ collection: 'treasury_accounts', timestamps: true })
export class TreasuryAccount {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  balance: number;

  @Prop({ default: true })
  manual: boolean;

  @Prop()
  lastReconciledAt?: Date;
}

export const TreasuryAccountSchema = SchemaFactory.createForClass(TreasuryAccount);
TreasuryAccountSchema.index({ clubId: 1, name: 1 });
