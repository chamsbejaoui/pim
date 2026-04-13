import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { TestType, TestTypeDocument, TestCategory, ScoringMethod } from './entities/test-type.entity';
import { CreateTestTypeDto } from './dto/create-test-type.dto';
import { UpdateTestTypeDto } from './dto/update-test-type.dto';

@Injectable()
export class TestTypesService {
    constructor(
        @InjectModel(TestType.name) private testTypeModel: Model<TestTypeDocument>,
    ) { }

    async onModuleInit() {
        await this.seedDefaultTestTypes();
    }

    private async seedDefaultTestTypes() {
        const defaultTypes = [
            // ── Physical ──────────────────────────────────────────
            { name: 'Acceleration (30m)', category: TestCategory.PHYSICAL, unit: 's', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Vitesse de démarrage', weight: 1.0, minValue: 3.5, maxValue: 10.0 },
            { name: 'Acceleration', category: TestCategory.PHYSICAL, unit: 's', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Vitesse de démarrage', weight: 1.0, minValue: 3.5, maxValue: 10.0 },
            { name: 'Stamina (VMA)', category: TestCategory.PHYSICAL, unit: 'km/h', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Endurance physique', weight: 1.0, minValue: 10, maxValue: 25 },
            { name: 'Stamina', category: TestCategory.PHYSICAL, unit: 'km/h', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Endurance physique', weight: 1.0, minValue: 10, maxValue: 25 },
            { name: 'Strength', category: TestCategory.PHYSICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Puissance physique', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Agility', category: TestCategory.PHYSICAL, unit: 's', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Changement de direction', weight: 1.0, minValue: 10.0, maxValue: 30.0 },
            { name: 'Vertical Jump', category: TestCategory.PHYSICAL, unit: 'cm', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Détente verticale', weight: 1.0, minValue: 20, maxValue: 110 },
            { name: 'Jump Reach', category: TestCategory.PHYSICAL, unit: 'cm', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Hauteur de saut', weight: 1.0, minValue: 200, maxValue: 360 },

            // ── Technical ─────────────────────────────────────────
            { name: 'Finishing', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Finition', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Shooting Power', category: TestCategory.TECHNICAL, unit: 'km/h', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Puissance de frappe', weight: 1.0, minValue: 50, maxValue: 180 },
            { name: 'Passing Accuracy', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Précision des passes', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Dribbling', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Maîtrise balle au pied', weight: 0.8, minValue: 0, maxValue: 100 },
            { name: 'Ball Control', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Contrôle du ballon', weight: 0.8, minValue: 0, maxValue: 100 },
            { name: 'Vision', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Lecture du jeu', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Tackling', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Efficacité des tacles', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Defensive Positioning', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Placement défensif', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Aerial Duel', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Duels aériens', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Off-ball Movement', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Déplacements sans ballon', weight: 0.8, minValue: 0, maxValue: 100 },
            { name: 'Handling', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Prise en main du ballon (GK)', weight: 1.0, minValue: 0, maxValue: 100 },
            { name: 'Distribution', category: TestCategory.TECHNICAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Relance (GK)', weight: 1.0, minValue: 0, maxValue: 100 },

            // ── Medical ───────────────────────────────────────────
            { name: 'Poids', category: TestCategory.MEDICAL, unit: 'kg', scoringMethod: ScoringMethod.RANGE, description: 'Poids corporel', weight: 1.0, minValue: 40, maxValue: 150 },
            { name: 'Taille', category: TestCategory.MEDICAL, unit: 'cm', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Taille du joueur', weight: 1.0, minValue: 140, maxValue: 230 },
            { name: 'Masse Grasse', category: TestCategory.MEDICAL, unit: '%', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Pourcentage de graisse', weight: 1.0, minValue: 5, maxValue: 35 },
            { name: 'Fréq. Cardiaque', category: TestCategory.MEDICAL, unit: 'bpm', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Fréquence au repos', weight: 1.0, minValue: 30, maxValue: 120 },

            // ── Mental ────────────────────────────────────────────
            { name: 'Decision Making', category: TestCategory.MENTAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Choix de jeu', weight: 0.8, minValue: 0, maxValue: 100 },
            { name: 'Awareness', category: TestCategory.MENTAL, unit: '%', scoringMethod: ScoringMethod.HIGHER_BETTER, description: 'Anticipation', weight: 0.8, minValue: 0, maxValue: 100 },

            // ── GK specific ───────────────────────────────────────
            { name: 'Reflexes', category: TestCategory.PHYSICAL, unit: 'ms', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Réflexes gardien', weight: 1.0, minValue: 100, maxValue: 1000 },
            { name: 'Reaction Time', category: TestCategory.PHYSICAL, unit: 'ms', scoringMethod: ScoringMethod.LOWER_BETTER, description: 'Temps de réaction', weight: 1.0, minValue: 100, maxValue: 1000 },
        ];

        // Always upsert — never delete existing data
        const existingTests = await this.testTypeModel.find({
            name: { $in: defaultTypes.map(t => t.name) }
        }).exec();

        const existingNames = new Set(existingTests.map(t => t.name));

        // Update existing ones to ensure professional scales are applied
        for (const existing of existingTests) {
            const defaults = defaultTypes.find(d => d.name === existing.name);
            if (defaults) {
                await this.testTypeModel.findByIdAndUpdate(existing._id, {
                    unit: defaults.unit,
                    minValue: (defaults as any).minValue,
                    maxValue: (defaults as any).maxValue,
                    weight: defaults.weight,
                });
            }
        }

        const toInsert = defaultTypes.filter(t => !existingNames.has(t.name));

        if (toInsert.length > 0) {
            console.log(`🚀 Inserting ${toInsert.length} missing test types...`);
            await this.testTypeModel.insertMany(toInsert);
        } else {
            console.log('✅ All default test types already exist.');
        }
    }

    async create(createTestTypeDto: CreateTestTypeDto): Promise<TestType> {
        const testType = new this.testTypeModel(createTestTypeDto);
        return testType.save();
    }

    async findAll(activeOnly: boolean = false): Promise<TestType[]> {
        const query = activeOnly ? { isActive: true } : {};
        return this.testTypeModel.find(query).exec();
    }

    async findOne(id: string): Promise<TestType> {
        const testType = await this.testTypeModel.findById(id).exec();
        if (!testType) {
            throw new NotFoundException(`TestType with ID ${id} not found`);
        }
        return testType;
    }

    async update(id: string, updateTestTypeDto: UpdateTestTypeDto): Promise<TestType> {
        const testType = await this.testTypeModel
            .findByIdAndUpdate(id, updateTestTypeDto, { new: true })
            .exec();
        if (!testType) {
            throw new NotFoundException(`TestType with ID ${id} not found`);
        }
        return testType;
    }

    async remove(id: string): Promise<void> {
        const result = await this.testTypeModel.findByIdAndDelete(id).exec();
        if (!result) {
            throw new NotFoundException(`TestType with ID ${id} not found`);
        }
    }
}
