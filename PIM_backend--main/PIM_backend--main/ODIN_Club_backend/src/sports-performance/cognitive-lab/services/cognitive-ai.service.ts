import { Injectable } from '@nestjs/common';
import { CreateCognitiveSessionDto } from '../dto/create-cognitive-session.dto';

@Injectable()
export class CognitiveAiService {

    /**
     * @function calculateScores
     * @description Calcule les scores individuels (0-100) pour chaque test ainsi qu'un score mental global.
     * Cette fonction transforme les données brutes (ms, erreurs, niveaux) en indicateurs de performance.
     */
    public calculateScores(dto: CreateCognitiveSessionDto) {
        let reactionScore: number | undefined;
        let focusScore: number | undefined;
        let memoryScore: number | undefined;
        let mentalScore: number | undefined;

        if (dto.reaction && dto.focus && dto.memory) {
            // --- Score de Réaction (Poids: 40%) ---
            reactionScore = 100;
            if (dto.reaction.avgMs > 400) reactionScore = 30;
            else if (dto.reaction.avgMs > 320) reactionScore = 60;
            else if (dto.reaction.avgMs > 250) reactionScore = 80;

            const commissionErrors = dto.reaction.commissionErrors ?? 0;
            reactionScore -= (commissionErrors * 5); 
            if (reactionScore < 0) reactionScore = 0;

            // --- Score de Focus (Poids: 30%) ---
            focusScore = 100;
            if (dto.focus.errors > 3) focusScore = 20;
            else if (dto.focus.errors > 1) focusScore = 50;
            else if (dto.focus.errors === 1) focusScore = 80;

            // --- Score de Mémoire (Poids: 30%) ---
            memoryScore = 100;
            if (dto.memory.maxLevel < 4) memoryScore = 50;
            else if (dto.memory.maxLevel < 5) memoryScore = 75;
            memoryScore -= (dto.memory.failures * 10);
            if (memoryScore < 0) memoryScore = 0;

            // Score mental global pondéré
            mentalScore = Math.round((reactionScore * 0.4) + (focusScore * 0.3) + (memoryScore * 0.3));
        }

        // --- Score de Décision Tactique (Optionnel) ---
        // Évalue la combinaison entre la précision et la rapidité de décision.
        let decisionScore: number | undefined;
        if (dto.decision) {
            const d = dto.decision;
            const accuracy = d.accuracy ?? 0;
            // Calcul de la vitesse : 500ms est l'idéal (100 pts), plus lent réduit le score.
            const speedScore = Math.max(0, 100 - Math.round(((d.avgDecisionTime ?? 4000) - 500) / 35));
            decisionScore = Math.round((accuracy * 0.6) + (speedScore * 0.4));
            if (decisionScore < 0) decisionScore = 0;
            if (decisionScore > 100) decisionScore = 100;
        }

        // --- Score de Wellness / Bien-être (Optionnel) ---
        // Analyse les données subjectives (sommeil, stress, douleurs) pour évaluer la récupération physique.
        let wellnessScore: number | undefined;
        if (dto.wellness) {
            const w = dto.wellness;
            const map = (val: string, map: Record<string, number>) => map[val] ?? 60;

            const sleepQualityScore = map(w.sleepQuality ?? 'Normal', {
                'Very Good': 100, 'Good': 80, 'Normal': 60, 'Poor': 40, 'Very Poor': 20
            });
            const soreScore = map(w.muscleSoreness ?? 'None', {
                'None': 100, 'Light': 80, 'Moderate': 50, 'Heavy': 20
            });
            const stressScore = map(w.stressLevel ?? 'Low', {
                'Low': 100, 'Moderate': 60, 'High': 20
            });
            const energyScore = map(w.energyLevel ?? 'Normal', {
                'High': 100, 'Normal': 60, 'Low': 20
            });
            const moodScore = map(w.mood ?? 'Normal', {
                'Excellent': 100, 'Good': 80, 'Normal': 60, 'Bad': 30
            });
            const motivationScore = map(w.motivation ?? 'Normal', {
                'High': 100, 'Normal': 60, 'Low': 20
            });
            const painScore = w.generalPain != null ? Math.round(100 - (w.generalPain * 10)) : 100;

            wellnessScore = Math.round(
                (sleepQualityScore + soreScore + stressScore + energyScore + moodScore + motivationScore + painScore) / 7
            );
        }

        // --- Recommandation de charge d'entraînement ---
        // Détermine si le joueur peut participer à une séance complète ou s'il doit être protégé.
        let trainingReadiness: string | undefined;
        if (decisionScore != null && wellnessScore != null) {
            if (decisionScore > 80 && wellnessScore > 80) {
                trainingReadiness = 'FULL TRAINING';
            } else if (decisionScore < 50 && wellnessScore < 50) {
                trainingReadiness = 'RECOVERY DAY';
            } else if (decisionScore < 60 || wellnessScore < 60) {
                trainingReadiness = 'LIGHT TRAINING';
            } else {
                trainingReadiness = 'NORMAL TRAINING';
            }
        }

        // --- Score de Mémoire Tactique (Tactical IQ) ---
        let tacticalIqScore: number | undefined;
        let tacticalProfile: string | undefined;

        if (dto.tacticalMemory) {
            const tm = dto.tacticalMemory;
            
            // Base score is 100
            let baseScore = 100;
            
            // L'erreur de distance est soustraite, le ballon est plus lourdement pénalisé (x1.5)
            // On présume que la distance est une valeur pondérée envoyée par Flutter
            const playerPenalty = tm.avgDistanceError; 
            const ballPenalty = tm.ballDistanceError * 1.5; 
            
            baseScore -= (playerPenalty + ballPenalty);

            // Bonus de Vitesse
            const expectedTimeMs = 8000; // 8 secondes est la norme
            if (tm.timeMs < expectedTimeMs) {
                const speedBonus = ((expectedTimeMs - tm.timeMs) / 1000) * 2; 
                baseScore += speedBonus;
            } else {
                const speedPenalty = ((tm.timeMs - expectedTimeMs) / 1000) * 1.5;
                baseScore -= speedPenalty;
            }

            tacticalIqScore = Math.round(baseScore);
            if (tacticalIqScore > 100) tacticalIqScore = 100;
            if (tacticalIqScore < 0) tacticalIqScore = 0;

            // Définition du Profil Scanner
            if (tacticalIqScore >= 80) tacticalProfile = 'Scanner';
            else if (tacticalIqScore >= 60) tacticalProfile = 'Standard';
            else tacticalProfile = 'At-Risk';
        }

        return { 
            reactionScore, focusScore, memoryScore, mentalScore, 
            decisionScore, wellnessScore, trainingReadiness,
            tacticalIqScore, tacticalProfile
        };
    }

    /**
     * @function generateAiAssessment
     * @description Moteur IA de diagnostic. Compare les scores actuels à la moyenne (baseline) 
     * pour détecter la fatigue nerveuse et générer des recommandations pour le staff médical.
     */
    public generateAiAssessment(currentScores: any, baselineScores?: any, dto?: CreateCognitiveSessionDto) {
        let aiStatus = 'NORMAL';
        let trainingSuggestion = 'Entraînement complet autorisé.';
        let aiRecommendationText = 'Performance cognitive stable.';
        let riskLevel = 'BAS (LOW)';

        const mentalScore = currentScores.mentalScore;

        // Analyse Cognitive de haut niveau (Seulement si les tests complets ont été passés)
        if (mentalScore !== undefined) {
            if (mentalScore >= 90) {
                aiStatus = 'PRÊT (READY)';
                aiRecommendationText = 'État de forme optimal. Le système nerveux est parfaitement préparé.';
            } else if (mentalScore < 40) {
                aiStatus = 'CRITIQUE';
                riskLevel = 'CRITIQUE';
                trainingSuggestion = 'Récupération uniquement.';
                aiRecommendationText = 'Fatigue cognitive sévère détectée. Risque de blessure élevé. Repos complet recommandé.';
            } else if (currentScores.reactionScore != null && currentScores.reactionScore < 50) {
                aiStatus = 'FATIGUÉ';
                riskLevel = 'HAUT (HIGH)';
                trainingSuggestion = 'Séance technique uniquement. Éviter toute surcharge neuromusculaire.';
                aiRecommendationText = 'Le temps de réaction est significativement plus lent que d\'habitude. Suspicion de fatigue nerveuse.';
            } else if (dto?.reaction?.commissionErrors && dto.reaction.commissionErrors > 2) {
                aiStatus = 'IMPULSIF';
                riskLevel = 'MOYEN (MEDIUM)';
                aiRecommendationText = 'Contrôle inhibiteur affaibli. Le joueur montre des signes d\'impulsivité motrice.';
            } else if (currentScores.memoryScore != null && currentScores.focusScore != null && currentScores.memoryScore < 40 && currentScores.focusScore < 40) {
                aiStatus = 'SURCHARGE';
                riskLevel = 'MOYEN (MEDIUM)';
                trainingSuggestion = 'Réduire l\'intensité de 20%. Révision tactique recommandée.';
                aiRecommendationText = 'Baisse des capacités de mémorisation et de focus. Le joueur subit une surcharge cognitive.';
            } else if (mentalScore < 75) {
                aiStatus = 'FATIGUÉ';
                riskLevel = 'MOYEN (MEDIUM)';
                trainingSuggestion = 'Réduire l\'intensité de 10-20%.';
                aiRecommendationText = 'Fatigue cognitive modérée observée. Surveiller la charge physique.';
            }
        } else {
            // Standalone Tactical Test
            aiRecommendationText = 'Évaluation tactique pure (Données cognitives non fournies).';
            aiStatus = 'ÉVALUÉ (TACTICAL)';
        }

        // Complément d'analyse sur la prise de décision
        if (currentScores.decisionScore != null && currentScores.decisionScore < 50) {
            aiRecommendationText += ' Vitesse de décision réduite — fatigue décisionnelle probable.';
            if (riskLevel === 'BAS (LOW)') riskLevel = 'MOYEN (MEDIUM)';
        }

        // Complément d'analyse sur le bien-être (Wellness)
        if (currentScores.wellnessScore != null && currentScores.wellnessScore < 50) {
            aiRecommendationText += ' Les indicateurs de bien-être sont sous le seuil — récupération active préconisée.';
            if (riskLevel === 'BAS (LOW)') riskLevel = 'MOYEN (MEDIUM)';
        }

        // Ajout de la readiness calculée au message final
        if (currentScores.trainingReadiness) {
            trainingSuggestion = `${currentScores.trainingReadiness}. ${trainingSuggestion}`;
        }

        // Complément d'analyse sur le profil Scanner (Tactical Memory)
        if (currentScores.tacticalProfile === 'At-Risk') {
            aiRecommendationText += ' Alerte Vision Tactique : difficulté majeure à retenir et spatialiser les informations du jeu.';
            if (riskLevel === 'BAS (LOW)') riskLevel = 'MOYEN (MEDIUM)';
            trainingSuggestion += ' Focus sur exercices cognitifs à blanc (sans ballon) recommandé.';
        }

        // Alerte Baseline : Détecte une chute de performance brutale (-15 points par rapport à la moyenne)
        if (mentalScore !== undefined && baselineScores && (baselineScores.mentalScore - mentalScore) > 15) {
            aiStatus = 'RÉCUPÉRATION REQUISE';
            riskLevel = 'HAUT (HIGH)';
            trainingSuggestion = 'Récupération ou séance technique légère.';
            aiRecommendationText = `La disponibilité mentale a chuté brutalement (-${Math.round(baselineScores.mentalScore - mentalScore)} pts vs moyenne). Alerte récupération.`;
        }

        return { aiStatus, riskLevel, aiRecommendationText, trainingSuggestion };
    }
}
