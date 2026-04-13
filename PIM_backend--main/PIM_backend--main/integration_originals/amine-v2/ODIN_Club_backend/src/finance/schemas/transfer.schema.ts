import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type TransferDocument = HydratedDocument<Transfer>;

@Schema({ _id: false })
export class TransferTranche {
  @Prop({ required: true })
  dueDate: Date;

  @Prop({ required: true })
  amount: number;

  @Prop({ default: 'PENDING', index: true })
  status: 'PENDING' | 'PAID';

  @Prop()
  paidAt?: Date;
}

@Schema({ collection: 'transfers', timestamps: true })
export class Transfer {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ required: true })
  playerName: string;

  @Prop({ required: true })
  direction: 'ACQUISITION' | 'TRANSFER';

  @Prop({ required: true })
  totalFee: number;

  @Prop({ required: true })
  contractYears: number;

  @Prop({ type: [TransferTranche], default: [] })
  tranches: TransferTranche[];
}

export const TransferSchema = SchemaFactory.createForClass(Transfer);
TransferSchema.index({ clubId: 1, 'tranches.dueDate': 1, 'tranches.status': 1 });
