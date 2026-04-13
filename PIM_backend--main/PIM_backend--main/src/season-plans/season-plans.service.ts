import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import axios from 'axios';
import { SeasonPlan, SeasonPlanDocument } from './schemas/season-plan.schema';
import {
  CreateCollectivePreparationDto,
  CreateSeasonPlanDto,
  CreateWeeklyCollectiveCheckinDto,
} from './dto/create-season-plan.dto';

@Injectable()
export class SeasonPlansService {
  constructor(
    @InjectModel(SeasonPlan.name) private seasonPlanModel: Model<SeasonPlanDocument>,
  ) {}

  async create(createDto: CreateSeasonPlanDto): Promise<SeasonPlan> {
    const created = new this.seasonPlanModel({
      ...createDto,
      collectivePreparation: this.ensureCollectivePreparation(createDto.collectivePreparation),
      weeklyCheckins: (createDto.weeklyCheckins ?? []).map((checkin) => this.normalizeCheckin(checkin)),
    });
    return created.save();
  }

  async findAll(): Promise<SeasonPlan[]> {
    return this.seasonPlanModel.find().exec();
  }

  async findOne(id: string): Promise<SeasonPlan> {
    const plan = await this.seasonPlanModel.findById(id).exec();
    if (!plan) {
      throw new NotFoundException(`SeasonPlan with ID ${id} not found`);
    }
    return plan;
  }

  async update(id: string, updateDto: any): Promise<SeasonPlan> {
    const normalizedUpdate = { ...updateDto };
    if (normalizedUpdate.collectivePreparation) {
      normalizedUpdate.collectivePreparation = this.ensureCollectivePreparation(
        normalizedUpdate.collectivePreparation,
      );
    }
    if (Array.isArray(normalizedUpdate.weeklyCheckins)) {
      normalizedUpdate.weeklyCheckins = normalizedUpdate.weeklyCheckins.map((checkin: any) =>
        this.normalizeCheckin(checkin),
      );
    }

    const updated = await this.seasonPlanModel
      .findByIdAndUpdate(id, normalizedUpdate, { new: true })
      .exec();
    if (!updated) {
      throw new NotFoundException(`SeasonPlan with ID ${id} not found`);
    }
    return updated;
  }

  async remove(id: string): Promise<SeasonPlan> {
    const deleted = await this.seasonPlanModel.findByIdAndDelete(id).exec();
    if (!deleted) {
      throw new NotFoundException(`SeasonPlan with ID ${id} not found`);
    }
    return deleted;
  }

  async generateMicroCycles(planId: string, macroId: string, weeksCount: number): Promise<SeasonPlan> {
    const plan = await this.seasonPlanModel.findById(planId).exec();
    if (!plan) throw new NotFoundException('Plan not found');

    const macro = plan.macroCycles.find((m) => (m as any)._id.toString() === macroId);
    if (!macro) throw new NotFoundException('MacroCycle not found');

    try {
      const response = await axios.post('http://localhost:8000/generate-microcycles', {
        macro_type: macro.type,
        weeks_count: weeksCount,
      });

      const generated = response.data.micro_cycles;

      const macroStart = macro.startDate ? new Date(macro.startDate) : null;
      macro.mesoCycles = [{
        name: `Bloc IA - Focus principal`,
        objective: 'Périodisation générée automatiquement par Antigravity AI',
        startDate: macro.startDate,
        endDate: macro.endDate,
        microCycles: generated.map((g: any) => ({
          weekNumber: g.weekNumber,
          focus: g.focus,
          label: g.label,
          objective: g.objective,
          trainingVolume: g.trainingVolume,
          intensityLevel: g.intensityLevel,
          chargeRpe: g.chargeRpe,
          ratioTravailRepos: g.ratioTravailRepos,
          keyExercises: g.keyExercises,
          medicalAdvice: g.medicalAdvice,
          indicateursProgression: g.indicateursProgression ?? [],
          nutritionRecommandee: g.nutritionRecommandee,
          sessionVideoTactique: g.sessionVideoTactique ?? false,
          startDate: macroStart
            ? this.addDays(macroStart, Math.max(0, (Number(g.weekNumber) - 1) * 7))
            : null,
          endDate: macroStart
            ? this.addDays(macroStart, Math.max(0, (Number(g.weekNumber) - 1) * 7 + 6))
            : null,
        })),
      } as any];

      return plan.save();
    } catch (e: any) {
      throw new Error(`Failed to generate via AI: ${e.message}`);
    }
  }

  async updateCollectivePreparation(
    id: string,
    dto: CreateCollectivePreparationDto,
  ): Promise<SeasonPlan> {
    const plan = await this.seasonPlanModel.findById(id).exec();
    if (!plan) {
      throw new NotFoundException(`SeasonPlan with ID ${id} not found`);
    }

    plan.collectivePreparation = this.ensureCollectivePreparation({
      ...(plan.collectivePreparation as any),
      ...dto,
    }) as any;

    return plan.save();
  }

  async addWeeklyCheckin(
    planId: string,
    dto: CreateWeeklyCollectiveCheckinDto,
  ): Promise<SeasonPlan> {
    const plan = await this.seasonPlanModel.findById(planId).exec();
    if (!plan) {
      throw new NotFoundException(`SeasonPlan with ID ${planId} not found`);
    }

    const normalized = this.normalizeCheckin(dto);
    const existingIndex = (plan.weeklyCheckins ?? []).findIndex(
      (checkin: any) => Number(checkin.weekNumber) === Number(normalized.weekNumber),
    );

    if (existingIndex >= 0) {
      (plan.weeklyCheckins as any[])[existingIndex] = normalized;
    } else {
      (plan.weeklyCheckins as any[]).push(normalized);
    }

    plan.weeklyCheckins = [...(plan.weeklyCheckins as any[])].sort(
      (a: any, b: any) => Number(a.weekNumber) - Number(b.weekNumber),
    ) as any;

    return plan.save();
  }

  async getDashboard(planId: string) {
    const plan = await this.seasonPlanModel.findById(planId).lean().exec();
    if (!plan) {
      throw new NotFoundException(`SeasonPlan with ID ${planId} not found`);
    }

    const collectivePreparation = this.ensureCollectivePreparation(
      (plan as any).collectivePreparation,
    );
    const weeklyCheckins = [...((plan as any).weeklyCheckins ?? [])].sort(
      (a: any, b: any) => Number(a.weekNumber) - Number(b.weekNumber),
    );
    const latestCheckin = weeklyCheckins.length > 0 ? weeklyCheckins[weeklyCheckins.length - 1] : null;

    const microCycles = this.flattenMicroCycles(plan as any);
    const chargeValues = microCycles
      .map((cycle: any) => Number(cycle.chargeRpe))
      .filter((value: number) => Number.isFinite(value));

    const averageRpe =
      chargeValues.length > 0
        ? Number((chargeValues.reduce((sum, value) => sum + value, 0) / chargeValues.length).toFixed(1))
        : 0;

    const highIntensityWeeks = microCycles.filter((cycle: any) => cycle.focus === 'HIGH_INTENSITY').length;
    const recoveryWeeks = microCycles.filter((cycle: any) => cycle.focus === 'RECOVERY').length;
    const videoSessions = microCycles.filter((cycle: any) => Boolean(cycle.sessionVideoTactique)).length;

    const readinessIndex = this.computeReadinessIndex(latestCheckin);

    const focusDistribution = this.computeFocusDistribution(microCycles);
    const macroTimeline = this.computeMacroTimeline((plan as any).macroCycles ?? []);
    const recommendations = this.buildRecommendations({
      readinessIndex,
      latestCheckin,
      averageRpe,
      highIntensityWeeks,
      recoveryWeeks,
      collectivePreparation,
      microCyclesCount: microCycles.length,
    });

    return {
      planId: (plan as any)._id?.toString(),
      title: plan.title,
      year: plan.year,
      collectivePreparation,
      latestCheckin,
      weeklyCheckins,
      readinessIndex,
      kpis: {
        totalMacroCycles: ((plan as any).macroCycles ?? []).length,
        totalMesoCycles: ((plan as any).macroCycles ?? []).reduce(
          (sum: number, macro: any) => sum + ((macro?.mesoCycles ?? []).length || 0),
          0,
        ),
        totalMicroCycles: microCycles.length,
        averageRpe,
        highIntensityWeeks,
        recoveryWeeks,
        videoSessions,
      },
      focusDistribution,
      macroTimeline,
      recommendations,
      generatedAt: new Date().toISOString(),
    };
  }

  private flattenMicroCycles(plan: any): any[] {
    const macroCycles = plan?.macroCycles ?? [];
    const cycles: any[] = [];
    for (const macro of macroCycles) {
      const mesoCycles = macro?.mesoCycles ?? [];
      for (const meso of mesoCycles) {
        cycles.push(...(meso?.microCycles ?? []));
      }
    }
    return cycles;
  }

  private computeFocusDistribution(microCycles: any[]) {
    const counters = {
      HIGH_INTENSITY: 0,
      RECOVERY: 0,
      MAINTENANCE: 0,
      OTHER: 0,
    };

    for (const cycle of microCycles) {
      const focus = String(cycle?.focus ?? '').toUpperCase();
      if (focus === 'HIGH_INTENSITY') {
        counters.HIGH_INTENSITY += 1;
      } else if (focus === 'RECOVERY') {
        counters.RECOVERY += 1;
      } else if (focus === 'MAINTENANCE') {
        counters.MAINTENANCE += 1;
      } else {
        counters.OTHER += 1;
      }
    }

    const total = microCycles.length || 1;
    return Object.entries(counters).map(([focus, count]) => ({
      focus,
      count,
      ratio: Number((count / total).toFixed(3)),
    }));
  }

  private computeMacroTimeline(macroCycles: any[]) {
    const now = new Date();
    return macroCycles.map((macro: any) => {
      const start = macro?.startDate ? new Date(macro.startDate) : null;
      const end = macro?.endDate ? new Date(macro.endDate) : null;

      let progressPct: number | null = null;
      if (start && end && end.getTime() > start.getTime()) {
        if (now.getTime() <= start.getTime()) {
          progressPct = 0;
        } else if (now.getTime() >= end.getTime()) {
          progressPct = 100;
        } else {
          const ratio =
            (now.getTime() - start.getTime()) / (end.getTime() - start.getTime());
          progressPct = Math.round(ratio * 100);
        }
      }

      return {
        id: macro?._id?.toString(),
        name: macro?.name ?? '',
        type: macro?.type ?? 'REST',
        startDate: start ? start.toISOString() : null,
        endDate: end ? end.toISOString() : null,
        progressPct,
      };
    });
  }

  private computeReadinessIndex(latestCheckin: any): number {
    if (!latestCheckin) {
      return 60;
    }

    const assimilation = this.clamp(Number(latestCheckin.tacticalAssimilation ?? 0), 0, 10);
    const cohesion = this.clamp(Number(latestCheckin.teamCohesion ?? 0), 0, 10);
    const morale = this.clamp(Number(latestCheckin.morale ?? 0), 0, 10);
    const fatigue = this.clamp(Number(latestCheckin.fatigue ?? 0), 0, 10);
    const load = this.clamp(Number(latestCheckin.physicalLoad ?? 0), 0, 10);
    const injuries = Math.max(0, Number(latestCheckin.injuries ?? 0));

    const base = ((assimilation + cohesion + morale) / 30) * 100;
    const loadPenalty = Math.max(0, load - 7) * 4;
    const fatiguePenalty = fatigue * 2;
    const injuryPenalty = injuries * 4;

    return this.clamp(Math.round(base - loadPenalty - fatiguePenalty - injuryPenalty + 8), 0, 100);
  }

  private buildRecommendations(input: {
    readinessIndex: number;
    latestCheckin: any;
    averageRpe: number;
    highIntensityWeeks: number;
    recoveryWeeks: number;
    collectivePreparation: any;
    microCyclesCount: number;
  }): string[] {
    const recommendations: string[] = [];

    if (input.readinessIndex < 55) {
      recommendations.push(
        'Prioriser 1 semaine de regeneration collective avec reduction du volume et seance video tactique ciblee.',
      );
    }

    if (input.latestCheckin && Number(input.latestCheckin.injuries ?? 0) >= 3) {
      recommendations.push(
        'Activer un protocole de prevention blessures (monitoring charge + adaptation des contenus de sprint).',
      );
    }

    if (input.averageRpe >= 7.5) {
      recommendations.push(
        'Reequilibrer la charge: alterner micro-cycles de maintenance et de recovery pour eviter la fatigue cumulative.',
      );
    }

    if (
      input.collectivePreparation?.targetCohesionScore &&
      input.latestCheckin &&
      Number(input.latestCheckin.teamCohesion ?? 0) <
        Number(input.collectivePreparation.targetCohesionScore)
    ) {
      recommendations.push(
        'Programmer des ateliers de cohesion (jeu reduit sous contrainte, leadership group, routines de communication).',
      );
    }

    if (input.microCyclesCount > 0 && input.recoveryWeeks === 0) {
      recommendations.push(
        'Aucune semaine recovery detectee: introduire des blocs de regeneration pour maintenir la disponibilite de l effectif.',
      );
    }

    if (recommendations.length === 0) {
      recommendations.push(
        'Maintenir la trajectoire actuelle et consolider les principes collectifs via des revues video hebdomadaires.',
      );
    }

    return recommendations;
  }

  private ensureCollectivePreparation(input?: Partial<CreateCollectivePreparationDto>) {
    return {
      competitionName: (input?.competitionName ?? '').trim(),
      gameModel: (input?.gameModel ?? '').trim(),
      primaryObjective: (input?.primaryObjective ?? '').trim(),
      secondaryObjectives: this.sanitizeStringArray(input?.secondaryObjectives),
      tacticalPrinciples: this.sanitizeStringArray(input?.tacticalPrinciples),
      culturalPrinciples: this.sanitizeStringArray(input?.culturalPrinciples),
      targetAvailabilityPct: this.clamp(Number(input?.targetAvailabilityPct ?? 85), 0, 100),
      targetCohesionScore: this.clamp(Number(input?.targetCohesionScore ?? 7), 0, 10),
      targetTacticalAssimilation: this.clamp(
        Number(input?.targetTacticalAssimilation ?? 7),
        0,
        10,
      ),
    };
  }

  private normalizeCheckin(input: Partial<CreateWeeklyCollectiveCheckinDto>) {
    return {
      weekNumber: Math.max(1, Number(input.weekNumber ?? 1)),
      date: input.date ? new Date(input.date) : new Date(),
      physicalLoad: this.clamp(Number(input.physicalLoad ?? 0), 0, 10),
      tacticalAssimilation: this.clamp(Number(input.tacticalAssimilation ?? 0), 0, 10),
      teamCohesion: this.clamp(Number(input.teamCohesion ?? 0), 0, 10),
      morale: this.clamp(Number(input.morale ?? 0), 0, 10),
      injuries: Math.max(0, Number(input.injuries ?? 0)),
      fatigue: this.clamp(Number(input.fatigue ?? 0), 0, 10),
      coachNotes: (input.coachNotes ?? '').trim(),
      actionItems: this.sanitizeStringArray(input.actionItems),
    };
  }

  private sanitizeStringArray(input?: string[]): string[] {
    if (!Array.isArray(input)) {
      return [];
    }
    return [...new Set(input.map((value) => value.trim()).filter((value) => value.length > 0))];
  }

  private addDays(date: Date, days: number): Date {
    const output = new Date(date);
    output.setDate(output.getDate() + days);
    return output;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }
}
