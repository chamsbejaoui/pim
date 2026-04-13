import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { TestType, TestTypeDocument, ScoringMethod } from '../test-types/entities/test-type.entity';

@Injectable()
export class ScoringService {
    constructor(
        @InjectModel(TestType.name) private testTypeModel: Model<TestTypeDocument>,
    ) { }

    /**
     * Calcule le score normalisé (0-100) à partir d'une valeur brute
     */
    async calculateNormalizedScore(rawValue: number, testTypeId: string): Promise<number> {
        const testType = await this.testTypeModel.findById(testTypeId).exec();

        if (!testType) {
            throw new NotFoundException(`TestType with ID ${testTypeId} not found`);
        }

        let score = 0;

        switch (testType.scoringMethod) {
            case ScoringMethod.HIGHER_BETTER:
                // Plus élevé = meilleur (ex: distance saut, vitesse max)
                score = this.normalizeHigherBetter(
                    rawValue,
                    testType.baselineThreshold,
                    testType.eliteThreshold
                );
                break;

            case ScoringMethod.LOWER_BETTER:
                // Plus bas = meilleur (ex: temps sprint, temps récupération)
                score = this.normalizeLowerBetter(
                    rawValue,
                    testType.baselineThreshold,
                    testType.eliteThreshold
                );
                break;

            case ScoringMethod.RANGE:
                // Dans une plage optimale (ex: fréquence cardiaque au repos)
                score = this.normalizeRange(rawValue, testType.optimalRange);
                break;

            default:
                score = 50; // Score neutre par défaut
        }

        return Math.max(0, Math.min(100, score)); // Clamp entre 0 et 100
    }

    /**
     * Normalise pour "plus élevé = mieux"
     * Formula: ((rawValue - baseline) / (elite - baseline)) * 100
     */
    private normalizeHigherBetter(value: number, baseline?: number, elite?: number): number {
        // Fallback to old min/max if thresholds not defined
        if (baseline === undefined || elite === undefined) {
            return Math.min(value, 100);
        }

        if (value <= baseline) return 0;
        if (value >= elite) return 100;

        return ((value - baseline) / (elite - baseline)) * 100;
    }

    /**
     * Normalise pour "plus bas = mieux"
     * Formula: 100 - ((rawValue - elite) / (baseline - elite)) * 100
     */
    private normalizeLowerBetter(value: number, baseline?: number, elite?: number): number {
        // Fallback if thresholds not defined
        if (baseline === undefined || elite === undefined) {
            return Math.max(0, 100 - value);
        }

        if (value <= elite) return 100;
        if (value >= baseline) return 0;

        return 100 - ((value - elite) / (baseline - elite)) * 100;
    }

    /**
     * Normalise pour une plage optimale
     */
    private normalizeRange(value: number, optimalRange?: { min: number; max: number }): number {
        if (!optimalRange) {
            return 50; // Score neutre si pas de plage définie
        }

        const { min, max } = optimalRange;
        const mid = (min + max) / 2;

        if (value >= min && value <= max) {
            // Dans la plage optimale
            // Plus proche du milieu = meilleur score
            const distanceFromPerfect = Math.abs(value - mid);
            const maxDistance = (max - min) / 2;
            return 100 - (distanceFromPerfect / maxDistance) * 20; // 80-100 dans la plage
        } else {
            // Hors de la plage optimale
            const distanceFromRange = value < min ? min - value : value - max;
            const rangeSize = max - min;
            const penalty = Math.min((distanceFromRange / rangeSize) * 80, 80);
            return Math.max(0, 80 - penalty);
        }
    }

    /**
     * Calcule le score global d'un joueur basé sur tous ses résultats de tests
     */
    async calculatePlayerOverallScore(
        testResults: Array<{ score: number; testTypeId: string }>,
    ): Promise<number> {
        if (testResults.length === 0) return 0;

        let totalWeightedScore = 0;
        let totalWeight = 0;

        for (const result of testResults) {
            const testType = await this.testTypeModel.findById(result.testTypeId).exec();
            if (testType) {
                const weight = testType.weight || 1;
                totalWeightedScore += result.score * weight;
                totalWeight += weight;
            }
        }

        return totalWeight > 0 ? totalWeightedScore / totalWeight : 0;
    }

    /**
     * Compare le score d'un joueur à la moyenne
     */
    compareToAverage(
        playerScore: number,
        eventAverage: number,
    ): {
        deviation: number;
        deviationPercent: number;
        performance: 'below_average' | 'average' | 'above_average' | 'excellent';
    } {
        const deviation = playerScore - eventAverage;
        const deviationPercent = eventAverage > 0 ? (deviation / eventAverage) * 100 : 0;

        let performance: 'below_average' | 'average' | 'above_average' | 'excellent';

        if (deviationPercent < -10) {
            performance = 'below_average';
        } else if (deviationPercent < 10) {
            performance = 'average';
        } else if (deviationPercent < 25) {
            performance = 'above_average';
        } else {
            performance = 'excellent';
        }

        return {
            deviation,
            deviationPercent,
            performance,
        };
    }

    /**
     * Identifie les top players (score > seuil)
     */
    identifyTopPlayers(
        players: Array<{ playerId: string; score: number }>,
        threshold: number = 75,
    ): Array<{ playerId: string; score: number }> {
        return players.filter(p => p.score >= threshold).sort((a, b) => b.score - a.score);
    }

    /**
     * Classement des joueurs par score
     */
    rankPlayers(
        players: Array<{ playerId: any; score: number }>,
    ): Array<{ playerId: any; score: number; rank: number }> {
        // Trier par score décroissant
        const sorted = [...players].sort((a, b) => b.score - a.score);

        // Attribuer les rangs (gérer les égalités)
        const ranked: Array<{ playerId: any; score: number; rank: number }> = [];
        let currentRank = 1;

        for (let i = 0; i < sorted.length; i++) {
            const player = sorted[i];

            // Si le score est identique au précédent, même rang
            if (i > 0 && sorted[i].score === sorted[i - 1].score) {
                ranked.push({
                    ...player,
                    rank: ranked[i - 1].rank,
                });
            } else {
                ranked.push({
                    ...player,
                    rank: currentRank,
                });
            }

            currentRank++;
        }

        return ranked;
    }

    /**
     * Calcule les statistiques d'un événement
     */
    calculateEventStatistics(scores: number[]): {
        averageScore: number;
        medianScore: number;
        standardDeviation: number;
        minScore: number;
        maxScore: number;
    } {
        if (scores.length === 0) {
            return {
                averageScore: 0,
                medianScore: 0,
                standardDeviation: 0,
                minScore: 0,
                maxScore: 0,
            };
        }

        // Moyenne
        const averageScore = scores.reduce((sum, score) => sum + score, 0) / scores.length;

        // Médiane
        const sortedScores = [...scores].sort((a, b) => a - b);
        const mid = Math.floor(sortedScores.length / 2);
        const medianScore =
            sortedScores.length % 2 === 0
                ? (sortedScores[mid - 1] + sortedScores[mid]) / 2
                : sortedScores[mid];

        // Écart-type
        const variance =
            scores.reduce((sum, score) => sum + Math.pow(score - averageScore, 2), 0) /
            scores.length;
        const standardDeviation = Math.sqrt(variance);

        // Min et max
        const minScore = Math.min(...scores);
        const maxScore = Math.max(...scores);

        return {
            averageScore,
            medianScore,
            standardDeviation,
            minScore,
            maxScore,
        };
    }

    /**
     * Identifie les forces et faiblesses d'un joueur
     */
    identifyStrengthsAndWeaknesses(
        testScores: Array<{ testName: string; score: number; category: string }>,
    ): {
        strengths: string[];
        weaknesses: string[];
    } {
        const strengths: string[] = [];
        const weaknesses: string[] = [];

        for (const test of testScores) {
            if (test.score >= 80) {
                strengths.push(`${test.testName} (${test.score.toFixed(1)}/100)`);
            } else if (test.score < 50) {
                weaknesses.push(`${test.testName} (${test.score.toFixed(1)}/100)`);
            }
        }

        return { strengths, weaknesses };
    }
}
