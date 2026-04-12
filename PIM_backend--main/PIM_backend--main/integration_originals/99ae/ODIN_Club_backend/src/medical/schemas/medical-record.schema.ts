import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";
import { Player } from "../../players/schemas/player.schema";

export type MedicalRecordDocument = MedicalRecord & Document;

@Schema({ timestamps: true, collection: "medical_records" })
export class MedicalRecord {
  @Prop({ type: Types.ObjectId, ref: Player.name, required: true, index: true })
  playerId: Types.ObjectId;

  @Prop({ required: true })
  injuryProbability: number;

  @Prop({ required: true })
  injured: boolean;

  @Prop({ required: true })
  injuryType: string;

  @Prop({ required: true })
  recoveryDays: number;

  @Prop({ required: true })
  severity: string;

  @Prop({ type: [String], default: [] })
  rehab: string[];

  @Prop({ type: [String], default: [] })
  prevention: string[];

  @Prop({ default: "" })
  warning: string;
}

export const MedicalRecordSchema = SchemaFactory.createForClass(MedicalRecord);
