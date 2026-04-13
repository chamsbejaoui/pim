import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type MatchDocument = Match & Document;

@Schema({ timestamps: true, collection: "matches" })
export class Match {
  @Prop({ required: true, index: true })
  providerName: string;

  @Prop({ required: true, index: true })
  providerMatchId: string;

  @Prop({ required: true })
  date: string;

  @Prop({ required: true })
  competitionName: string;

  @Prop({ required: true })
  season: string;

  @Prop({ required: true })
  homeTeam: string;

  @Prop({ required: true })
  awayTeam: string;

  @Prop({ required: true })
  homeScore: number;

  @Prop({ required: true })
  awayScore: number;
}

export const MatchSchema = SchemaFactory.createForClass(Match);
MatchSchema.index({ providerName: 1, providerMatchId: 1 }, { unique: true });
