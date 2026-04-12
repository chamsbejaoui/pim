import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type MatchPlayerDocument = MatchPlayer & Document;

@Schema({ timestamps: true, collection: "match_players" })
export class MatchPlayer {
  @Prop({ required: true, index: true })
  providerName: string;

  @Prop({ required: true, index: true })
  providerMatchId: string;

  @Prop({ required: true, index: true })
  providerPlayerId: string;

  @Prop({ required: true })
  teamName: string;

  @Prop({ required: true, enum: ["starter", "sub"] })
  lineupStatus: "starter" | "sub";

  @Prop({ required: true })
  minutes: number;

  @Prop({ required: true })
  position: string;

  @Prop({ required: true })
  rating: number;

  @Prop({ required: true })
  goals: number;

  @Prop({ required: true })
  assists: number;

  @Prop({ required: true })
  shots: number;

  @Prop({ required: true })
  passes: number;

  @Prop({ required: true })
  tackles: number;

  @Prop({ required: true })
  yellowCards: number;

  @Prop({ required: true })
  redCards: number;
}

export const MatchPlayerSchema = SchemaFactory.createForClass(MatchPlayer);
MatchPlayerSchema.index(
  { providerName: 1, providerMatchId: 1, providerPlayerId: 1 },
  { unique: true },
);
