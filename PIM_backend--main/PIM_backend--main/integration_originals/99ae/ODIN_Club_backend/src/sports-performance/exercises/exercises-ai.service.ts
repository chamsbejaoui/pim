import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { Exercise, ExerciseCategory, PitchPosition } from './entities/exercise.entity';
import { TestResult, TestResultDocument } from '../test-results/entities/test-result.entity';
import { TestType, TestTypeDocument, PerformanceMetric } from '../test-types/entities/test-type.entity';
import { Event, EventDocument, EventType, EventStatus } from '../events/entities/event.entity';
import { EventPlayer, EventPlayerDocument } from '../event-players/entities/event-player.entity';
import { Model, Types } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';

@Injectable()
export class ExercisesAiService {
    private readonly logger = new Logger(ExercisesAiService.name);
    private readonly openaiApiKey: string;
    private readonly dalleApiKey: string;
    private readonly googleApiKey: string;

    private readonly MEDIA_LIBRARY = {
        Technical: [
            // Dribble technique - joueur pro
            'https://media.giphy.com/media/26uf2YTgF5upXUTm0/giphy.gif',
            // Contrôle de balle / passe précise
            'https://media.giphy.com/media/3o7TKOnPuk5G1v68/giphy.gif',
            // Frappe / finition pro
            'https://media.giphy.com/media/xT5LMGupUKCHb7B3fy/giphy.gif',
        ],
        Physical: [
            // Sprint explosif athlète
            'https://media.giphy.com/media/26uf16uVWQxY9Mkpq/giphy.gif',
            // Course athlète haute intensité
            'https://media.giphy.com/media/3o7TKVUn7iM8FMEU24/giphy.gif',
            // Agilité / escalier de foot
            'https://media.giphy.com/media/l41lTfuxmS2j9-C8M/giphy.gif',
        ],
        Tactical: [
            // Organisation défensive
            'https://media.giphy.com/media/3o7TKPVvM81N9O3UDS/giphy.gif',
            // Pressing pressing bloc
            'https://media.giphy.com/media/xT9IgvYbBTM0YFKlkA/giphy.gif',
        ],
        Cognitive: [
            // Réflexe / réaction rapide
            'https://media.giphy.com/media/3o7abwbzKeaRksvVaE/giphy.gif',
            // Prise de décision / vision
            'https://media.giphy.com/media/26uf2YTgF5upXUTm0/giphy.gif',
        ],
        Positions: {
            // Gardien - plongeon / arrêt
            GK: 'https://media.giphy.com/media/3oEjHYqA9OVFe3L1Bu/giphy.gif',
            // Défenseur - duel/tacle
            DEF: 'https://media.giphy.com/media/xT9IgvYbBTM0YFKlkA/giphy.gif',
            // Milieu - conduite / passe longue
            MID: 'https://media.giphy.com/media/26uf2YTgF5upXUTm0/giphy.gif',
            // Attaquant - dribble / frappe
            ATT: 'https://media.giphy.com/media/xT5LMGupUKCHb7B3fy/giphy.gif',
        }
    };

    constructor(
        private readonly httpService: HttpService,
        private readonly configService: ConfigService,
        @InjectModel(TestResult.name) private testResultModel: Model<TestResultDocument>,
        @InjectModel(TestType.name) private testTypeModel: Model<TestTypeDocument>,
        @InjectModel(Event.name) private eventModel: Model<EventDocument>,
        @InjectModel(EventPlayer.name) private eventPlayerModel: Model<EventPlayerDocument>,
    ) {
        this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY') || '';
        this.googleApiKey = this.configService.get<string>('GOOGLE_API_KEY') || '';
        this.dalleApiKey = this.configService.get<string>('DALLE_API_KEY') || this.openaiApiKey;

        if (this.googleApiKey) {
            this.logger.log('Gemini 1.5 Flash (Google) is active for TEXT generation.');
        } else if (!this.openaiApiKey) {
            this.logger.warn('Neither Google nor OpenAI API keys found. Using mock data.');
        }

        this.logger.log('Pollinations.ai is active for TACTICAL DIAGRAMS (Free Mode).');

        // Diagnostic immédiat au démarrage
        if (this.googleApiKey) {
            this.checkAvailableModels();
        }
    }

    private async checkAvailableModels() {
        try {
            const listUrl = `https://generativelanguage.googleapis.com/v1beta/models?key=${this.googleApiKey}`;
            const listRes = await firstValueFrom(this.httpService.get(listUrl));
            this.logger.log(`[DIAGNOSTIC] AVAILABLE MODELS: ${JSON.stringify(listRes.data.models.map(m => m.name))}`);
        } catch (e: any) {
            this.logger.error(`[DIAGNOSTIC] Failed to list models: ${e?.message}`);
        }
    }

    private async fetchPlayerWeaknessContext(playerId: string): Promise<string> {
        if (!playerId || !Types.ObjectId.isValid(playerId)) return '';

        try {
            // Step 1: Find all EventPlayer records for this specific player
            const eventPlayers = await this.eventPlayerModel.find({
                playerId: new Types.ObjectId(playerId)
            }).exec();

            if (eventPlayers.length === 0) return '';

            const eventPlayerIds = eventPlayers.map(ep => ep._id);

            // Step 2: Find TestResults linked to those EventPlayers
            const results = await this.testResultModel.find({
                eventPlayerId: { $in: eventPlayerIds }
            })
                .populate('testTypeId')
                .sort({ recordedAt: -1 })
                .limit(30)
                .exec();

            // Step 3: Extract weaknesses (score < 50)
            const weaknesses = results
                .filter(r => r.normalizedScore < 50 && (r.testTypeId as any)?.impactedMetric)
                .map(r => (r.testTypeId as any).impactedMetric);

            if (weaknesses.length > 0) {
                const uniqueWeaknesses = [...new Set(weaknesses)];
                return `IMPORTANT : Le joueur a des lacunes identifiées dans les domaines suivants : ${uniqueWeaknesses.join(', ')}. Priorise des exercices qui travaillent ces aspects.`;
            }
        } catch (e: any) {
            this.logger.error(`Error fetching weaknesses: ${e?.message}`);
        }
        return '';
    }

    private async fetchPlayerMatchLoadContext(playerId: string): Promise<string> {
        if (!playerId || !Types.ObjectId.isValid(playerId)) return '';

        try {
            // Rechercher les participations du joueur à des matchs complétés
            const participations = await this.eventPlayerModel.find({
                playerId: new Types.ObjectId(playerId)
            }).exec();

            if (participations.length === 0) return '';

            const eventIds = participations.map(p => p.eventId);

            // Trouver le match le plus récent parmi ces participations
            const lastMatch = await this.eventModel.findOne({
                _id: { $in: eventIds },
                type: EventType.MATCH,
                status: EventStatus.COMPLETED
            })
                .sort({ date: -1 })
                .exec();

            if (!lastMatch) return '';

            const hoursSinceMatch = (new Date().getTime() - new Date(lastMatch.date).getTime()) / (1000 * 60 * 60);

            // Récupérer les stats de ce match spécifique pour ce joueur
            const lastParticipation = participations.find(p => p.eventId.toString() === (lastMatch as any)._id.toString());
            const distance = lastParticipation?.aiAnalysis?.metrics?.distance || 0;

            if (hoursSinceMatch < 24) {
                return `CHARGE DE MATCH CRITIQUE : Le joueur a disputé un match il y a moins de 24h (Distance: ${distance}km). Le repos ou la récupération active est OBLIGATOIRE.`;
            } else if (hoursSinceMatch < 50) {
                return `CHARGE DE MATCH MODÉRÉE : Match disputé il y a ~${Math.round(hoursSinceMatch)}h. Évite les séances de haute intensité (VMA/Sprint).`;
            }
        } catch (e: any) {
            this.logger.error(`Error fetching match load: ${e?.message}`);
        }
        return '';
    }

    async getPlayerInsights(playerId: string): Promise<{ weaknesses: string, matchLoad: string }> {
        const performanceContext = await this.fetchPlayerWeaknessContext(playerId);
        const matchLoadContext = await this.fetchPlayerMatchLoadContext(playerId);

        return {
            weaknesses: performanceContext,
            matchLoad: matchLoadContext
        };
    }

    private getRandomMedia(category: string, position: PitchPosition): string {
        const catList = this.MEDIA_LIBRARY[category] || this.MEDIA_LIBRARY.Technical;
        const posMedia = this.MEDIA_LIBRARY.Positions[position];
        if (['GK', 'DEF'].includes(position) && Math.random() > 0.5) return posMedia;
        return catList[Math.floor(Math.random() * catList.length)];
    }

    async generateDrill(context: {
        targetPosition: PitchPosition;
        ageGroup: string;
        durationMinutes: number;
        primaryObjective: string;
        currentFatigueLevel: number;
        playerId?: string;
    }): Promise<any> {
        if (!this.googleApiKey && !this.openaiApiKey) {
            return await this.generateMockDrill(context);
        }

        // DIAGNOSTIC : Lister les modèles pour comprendre le 404
        try {
            const listUrl = `https://generativelanguage.googleapis.com/v1beta/models?key=${this.googleApiKey}`;
            const listRes = await firstValueFrom(this.httpService.get(listUrl));
            this.logger.log(`AVAILABLE MODELS: ${JSON.stringify(listRes.data.models.map(m => m.name))}`);
        } catch (e: any) {
            this.logger.error(`Failed to list models: ${e?.message}`);
        }

        const performanceContext = context.playerId
            ? await this.fetchPlayerWeaknessContext(context.playerId)
            : '';
        const matchLoadContext = context.playerId
            ? await this.fetchPlayerMatchLoadContext(context.playerId)
            : '';

        const systemPrompt = `Tu es un coach de football élite. Génère un exercice innovant et efficace.
L'objectif est de répondre exclusivement au format JSON pur en respectant exactement cette structure :
{
  "name": "Nom de l'exercice",
  "category": "Physical|Technical|Tactical|Cognitive",
  "difficulty": 1-5,
  "intensity": "Low|Medium|High",
  "technicalDetails": {
    "description": "Description UNIQUE et CRÉATIVE de l'exercice (min 3 phrases).",
    "sets": "Nombre de séries adapté",
    "reps": "Nombre de répétitions adapté",
    "restTime": "Temps de repos (ex: 90s)",
    "coachingCues": ["Conseil technique spécifique 1", "Conseil technique spécifique 2"],
    "equipment": ["Matériel"],
    "steps": ["Étape 1 détaillée", "Étape 2 détaillée", "Étape 3 détaillée"]
  },
  "performanceImpact": {
    "speed": 0-10,
    "endurance": 0-10,
    "technique": 0-10
  }
}
CONSIGNES DE QUALITÉ : 
1. Ne recycle jamais les mêmes descriptions. Chaque exercice doit être une création originale adaptée au contexte.
2. Les 'steps' doivent décrire une progression logique et concrète.
3. Évite les formulations génériques.
${performanceContext}
${matchLoadContext}`;

        const userPrompt = `Génère un exercice pour un joueur au poste [${context.targetPosition}] de catégorie [${context.ageGroup}]. 
L'objectif est [${context.primaryObjective}] avec un niveau de fatigue actuel de [${context.currentFatigueLevel}%]. 
Prends en compte la fatigue pour ajuster l'intensité.`;

        try {
            let content;
            if (this.googleApiKey) {
                // STRATEGY 2.5 PRIORITAIRE (Confirmée par vos logs comme étant la plus stable)
                const models = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-lite-latest'];
                let response;
                let lastError;

                for (const modelName of models) {
                    for (const apiVersion of ['v1beta', 'v1']) {
                        try {
                            const geminiUrl = `https://generativelanguage.googleapis.com/${apiVersion}/models/${modelName}:generateContent?key=${this.googleApiKey}`;
                            response = await firstValueFrom(
                                this.httpService.post(geminiUrl, {
                                    contents: [{
                                        parts: [{
                                            text: `${systemPrompt}\n\nUSER REQUEST: ${userPrompt}\n\nIMPORTANT: Return ONLY a valid JSON object matching the requested schema. No prose.`
                                        }]
                                    }],
                                    generationConfig: { temperature: 0.7 }
                                })
                            );
                            if (response) {
                                this.logger.log(`✅ Gemini success with model: ${modelName} on ${apiVersion}`);
                                break;
                            }
                        } catch (e: any) {
                            lastError = e;
                            this.logger.warn(`❌ Model ${modelName} on ${apiVersion} failed. Trying next...`);
                        }
                    }
                    if (response) break;
                }
                if (!response) throw lastError;

                const rawText = response.data.candidates[0].content.parts[0].text;
                const cleanedText = rawText.replace(/```json|```/g, '').trim();
                content = JSON.parse(cleanedText);
            } else {
                // Fallback OpenAI (Payant)
                const response = await firstValueFrom(
                    this.httpService.post(
                        'https://api.openai.com/v1/chat/completions',
                        {
                            model: 'gpt-4o-mini',
                            messages: [
                                { role: 'system', content: systemPrompt },
                                { role: 'user', content: userPrompt },
                            ],
                            response_format: { type: 'json_object' },
                            temperature: 0.7,
                        },
                        {
                            headers: {
                                'Authorization': `Bearer ${this.openaiApiKey}`,
                                'Content-Type': 'application/json',
                            },
                        },
                    ),
                );
                content = JSON.parse(response.data.choices[0].message.content);
            }

            let imageUrl: string;
            try {
                this.logger.log(`Génération du schéma tactique pour: ${content.name}`);
                const tacticalPrompt = `Professional 2D 3D tactical soccer training diagram for ${content.name} high quality clean architectural sports graphic style bird eye view green pitch white lines orange cones blue red players`;

                imageUrl = await this.generateImage(content.name, tacticalPrompt);
            } catch (imageError: any) {
                this.logger.warn(`DALL-E generation failed (${imageError?.message}). Falling back to media library.`);
                imageUrl = this.getRandomMedia(content.category, context.targetPosition);
            }

            return {
                ...content,
                aiGenerated: true,
                imageUrl,
                duration: context.durationMinutes,
                targetPositions: [context.targetPosition],
                generationContext: {
                    objective: context.primaryObjective,
                    playerFatigueAtGeneration: context.currentFatigueLevel,
                    aiModelUsed: this.googleApiKey ? 'Gemini-1.5-Flash + Pollinations' : 'gpt-4o-mini + fallback',
                    aiConfidenceScore: 0.98,
                }
            };
        } catch (error: any) {
            if (error?.response?.data) {
                this.logger.error(`GEMINI ERROR DETAILS: ${JSON.stringify(error.response.data)}`);
            }
            this.logger.error(`AI Flow encountered an error: ${error?.message}`);

            // SI ERREUR 429 (Quota), 400 (Bad Request), 404 (Not Found) ou autre lié à l'API
            if (error?.message?.includes('429') || error?.message?.includes('400') || error?.message?.includes('404') || error?.message?.includes('quota') || error?.message?.includes('not found')) {
                this.logger.warn(`API ISSUE DETECTED (${error?.message}): Switching to Intelligent Simulation Mode.`);
                return await this.generateMockDrill(context);
            }

            throw new HttpException('Failed to generate AI drill', HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private async generateMockDrill(context: any) {
        this.logger.log('Generating MOCK drill data');

        const difficulty = Math.floor(Math.random() * 4) + 2;
        const sets = "3-4";
        const reps = "8-10";
        const perfBase = Math.floor(Math.random() * 5) + 5;

        const pos = context.targetPosition;
        const obj = context.primaryObjective || 'la performance';
        const isDefensive = ['GK', 'DEF'].includes(pos);
        const drillType = isDefensive ? 'Coordination & Réflexes' : 'Finition & Agilité';
        const category = isDefensive ? 'Tactical' : 'Technical';

        // Utilisation de la méthode centralisée pour l'image
        const prompt = `Professional soccer tactical diagram ${drillType} ${obj} green pitch`;
        const imageUrl = await this.generateImage('MockDrill', prompt);

        this.logger.log(`Mock Image target URL: ${imageUrl}`);
        const descriptions = [
            `Circuit dynamique de ${drillType} pour le poste de ${pos}. Cet exercice cible principalement ${obj}.`,
            `Entraînement spécifique ${pos} focalisé sur l'intensité et le travail de ${obj}.`,
            `Séquence de travail cognitif et physique spécialisée pour ${pos}, optimisée pour ${obj}.`
        ];

        const stepTemplates = [
            [
                `Mise en place d'un atelier spécifique pour le travail de ${pos}.`,
                `Séquence d'échauffement orientée vers [${obj}].`,
                `Exercice principal : application directe des principes de [${obj}].`,
                `Correction technique en temps réel sur la posture et l'efficacité.`,
                `Retour au calme avec analyse des progrès sur [${obj}].`
            ],
            [
                `Positionnement initial optimisé pour ${pos}.`,
                `Engagement maximal sur la phase de [${obj}].`,
                `Action spécifique répétée 3 fois avec focus sur la précision.`,
                `Récupération courte active (trottinement).`,
                `Synthèse de la séance et validation de l'objectif : [${obj}].`
            ],
            [
                `Observation de la zone de jeu et prise d'info.`,
                `Explosion vers le ballon avec intention de [${obj}].`,
                `Duel ou enchaînement technique favorisant [${obj}].`,
                `Transition rapide vers une phase défensive/offensive.`,
                `Analyse vidéo mentale de la réussite sur [${obj}].`
            ]
        ];

        const selectedDesc = descriptions[Math.floor(Math.random() * descriptions.length)];
        const selectedSteps = stepTemplates[Math.floor(Math.random() * stepTemplates.length)];

        return {
            name: `${drillType} : ${obj} - ${pos}`,
            category: category,
            difficulty: difficulty,
            intensity: context.currentFatigueLevel > 70 ? 'Low' : 'High',
            duration: context.durationMinutes,
            aiGenerated: true,
            imageUrl,
            targetPositions: [pos],
            technicalData: {
                description: selectedDesc,
                steps: selectedSteps,
                sets: sets,
                reps: reps,
                restTime: '60s',
                coachingCues: ['Stay low', 'High focus'],
                equipment: ['Cones', 'Balls'],
            },
            performanceImpact: {
                speed: perfBase,
                endurance: perfBase - 2,
                technique: perfBase - 1,
            },
            generationContext: {
                objective: obj,
                playerFatigueAtGeneration: context.currentFatigueLevel,
                aiModelUsed: 'MockProviderV2',
                aiConfidenceScore: 1.0,
            }
        };
    }

    private async generateImage(name: string, tacticalPrompt: string): Promise<string> {
        // Pollinations.ai : Nettoyage RADICAL pour éviter les URLs corrompues
        // On enlève les accents, on remplace tout sauf lettres/chiffres par des tirets
        const slug = tacticalPrompt.normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "") // Enlever accents
            .replace(/[^a-zA-Z0-9]/g, "-")   // Tout ce qui n'est pas alphanum -> tiret
            .replace(/-+/g, "-")            // Éviter doubles tirets
            .toLowerCase()
            .substring(0, 150);             // Max 150 chars pour être sûr

        const imageUrl = `https://image.pollinations.ai/prompt/${slug}.jpg?seed=${Math.floor(Math.random() * 1000)}`;
        this.logger.log(`Image URL generated: ${imageUrl}`);
        return imageUrl;
    }
}
