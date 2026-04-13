import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SimulationMatchDocument = SimulationMatch & Document;

@Schema({ _id: false })
export class SimulationMatchStats {
  @Prop({ required: true })
  homeScore: number;

  @Prop({ required: true })
  awayScore: number;

  @Prop({ required: true })
  possessionHome: number;

  @Prop({ required: true })
  shotsHome: number;

  @Prop({ required: true })
  shotsAway: number;

  @Prop({ required: true })
  shotsOnTargetHome: number;

  @Prop({ required: true })
  shotsOnTargetAway: number;
}

@Schema({ _id: false })
export class SimulationInjuredPlayer {
  @Prop({ required: true })
  playerId: string;

  @Prop({ required: true })
  name: string;

  @Prop()
  injuryType?: string;

  @Prop()
  recoveryDays?: number;

  @Prop()
  severity?: string;

  @Prop({ required: true })
  injuryProbability: number;
}

@Schema({ _id: false })
export class SimulationPlayerResult {
  @Prop({ required: true })
  playerId: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  fatigue: number;

  @Prop({ required: true })
  load: number;

  @Prop({ required: true })
  injuryProbability: number;

  @Prop({ required: true })
  status: string;

  @Prop()
  injuryType?: string;

  @Prop()
  recoveryDays?: number;

  @Prop()
  severity?: string;

  @Prop({ required: true })
  playedMatch: boolean;

  @Prop({ required: true })
  playedAt: string;
}

@Schema({ timestamps: true, collection: 'simulation_matches' })
export class SimulationMatch {
  @Prop({ required: true, index: true })
  matchId: string;

  @Prop({ required: true })
  endedAt: string;

  @Prop({ type: SimulationMatchStats, required: true })
  stats: SimulationMatchStats;

  @Prop({ required: true })
  injuredCount: number;

  @Prop({ required: true })
  warningCount: number;

  @Prop({ required: true })
  safeCount: number;

  @Prop({ type: [SimulationInjuredPlayer], default: [] })
  injuredPlayers: SimulationInjuredPlayer[];

  @Prop({ type: [SimulationPlayerResult], default: [] })
  results: SimulationPlayerResult[];
}

export const SimulationMatchSchema = SchemaFactory.createForClass(SimulationMatch);
