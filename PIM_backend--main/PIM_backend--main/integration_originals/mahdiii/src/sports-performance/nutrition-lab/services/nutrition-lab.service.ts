import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PhysicalProfile } from '../entities/physical-profile.entity';
import { NutritionLog } from '../entities/nutrition-log.entity';
import { CreatePhysicalProfileDto } from '../dto/create-physical-profile.dto';
import { LogNutritionDto } from '../dto/log-nutrition.dto';

@Injectable()
export class NutritionLabService {
  constructor(
    @InjectModel(PhysicalProfile.name) private physicalProfileModel: Model<PhysicalProfile>,
    @InjectModel(NutritionLog.name) private nutritionLogModel: Model<NutritionLog>,
  ) {}

  async createOrUpdatePhysicalProfile(userId: string, dto: CreatePhysicalProfileDto): Promise<PhysicalProfile> {
    return this.physicalProfileModel.findOneAndUpdate(
      { userId },
      { $set: dto },
      { new: true, upsert: true }
    );
  }

  async getPhysicalProfile(userId: string): Promise<PhysicalProfile> {
    const profile = await this.physicalProfileModel.findOne({ userId });
    if (!profile) {
      throw new NotFoundException(`Physical profile not found for user ${userId}`);
    }
    return profile;
  }

  async logNutrition(dto: LogNutritionDto): Promise<NutritionLog> {
    const log = new this.nutritionLogModel(dto);
    return log.save();
  }

  async getTodaysNutritionLogs(userId: string): Promise<NutritionLog[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.nutritionLogModel.find({
      userId,
      createdAt: { $gte: today }
    });
  }

  async getWeeklyMealPlan(userId: string) {
    const profile = await this.getPhysicalProfile(userId);
    
    // 1. CALCUL DU BMR DE BASE
    const birthDate = new Date(profile.dateNaissance);
    const age = new Date().getFullYear() - birthDate.getFullYear();
    const bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * age) + 5;

    // 2. BIBLIOTHÈQUE DE REPAS IA ÉTENDUE (28 VARIATIONS)
    const mealLibrary = {
      breakfasts: [
        { name: 'Petit-Déjeuner Vitalité', description: 'Avoine, baies fraîches, œufs pochés et thé vert.', icon: 'breakfast_dining' },
        { name: 'Petit-Déjeuner Keto-Sport', description: 'Omelette épinards, avocat, pain complet aux graines.', icon: 'egg' },
        { name: 'Petit-Déjeuner Force', description: 'Skyr islandais, noix de cajou, miel et rondelles de banane.', icon: 'breakfast_dining' },
        { name: 'Petit-Déjeuner Performance', description: 'Pancakes protéinés, myrtilles et beurre de cacahuète.', icon: 'cake' },
        { name: 'Petit-Déjeuner Omega', description: 'Tartines de seigle, saumon fumé et graines de chia.', icon: 'restaurant' },
        { name: 'Petit-Déjeuner Zen', description: 'Porridge au lait d’amande, cannelle et éclats de noisettes.', icon: 'breakfast_dining' },
        { name: 'Petit-Déjeuner Punch', description: 'Burrito matin : œufs brouillés, haricots noirs et salsa.', icon: 'fastfood' },
      ],
      lunches: [
        { name: 'Déjeuner Équilibré', description: 'Poulet grillé, quinoa aux herbes et patates douces.', icon: 'lunch_dining' },
        { name: 'Déjeuner Océan', description: 'Saumon poêlé, riz basmati et asperges vapeur.', icon: 'restaurant' },
        { name: 'Déjeuner Force Rouge', description: 'Steak de bœuf maigre, pommes de terre grenailles et salade.', icon: 'lunch_dining' },
        { name: 'Déjeuner Pasta-Pro', description: 'Pâtes complètes, thon blanc, tomates cerises et olives.', icon: 'ramen_dining' },
        { name: 'Déjeuner Power-Bowl', description: 'Falafels maison, houmous, boulgour et kale.', icon: 'restaurant' },
        { name: 'Déjeuner Méditerranéen', description: 'Dorade grillée, ratatouille et polenta crémeuse.', icon: 'lunch_dining' },
        { name: 'Déjeuner Asian-Fit', description: 'Wok de dinde, nouilles de riz et légumes croquants.', icon: 'ramen_dining' },
      ],
      snacks: [
        { name: 'Collation Énergie', description: 'Banane, beurre d’amande et shake de Whey isolate.', icon: 'fitness_center' },
        { name: 'Collation Récupération', description: 'Fromage blanc 0%, amandes grillées et pomme granny.', icon: 'apple' },
        { name: 'Collation Muscle-Up', description: 'Barre protéinée artisanale et yaourt grec.', icon: 'fitness_center' },
        { name: 'Collation Flash-Hydra', description: 'Smoothie épinards, protéine vanille et ananas.', icon: 'local_drink' },
        { name: 'Collation Crunchy', description: 'Bâtonnets de céleri, beurre de cacahuète et raisins secs.', icon: 'apple' },
        { name: 'Collation Choco-Fit', description: 'Carré de chocolat noir 85% et poignées de noix.', icon: 'cake' },
        { name: 'Collation Berry-Blast', description: 'Fromage de chèvre frais, fraises et filet de miel.', icon: 'restaurant' },
      ],
      dinners: [
        { name: 'Dîner Léger', description: 'Poisson blanc croustillant, brocolis et lentilles corail.', icon: 'dinner_dining' },
        { name: 'Dîner Détox', description: 'Dinde au curry doux, pois chiches et courgettes braisées.', icon: 'dinner_dining' },
        { name: 'Dîner Zen-Pro', description: 'Crevettes sautées, nouilles de sarrasin et poivrons.', icon: 'dinner_dining' },
        { name: 'Dîner Réparation', description: 'Soupe de légumes riche, œufs durs et pain de seigle grillé.', icon: 'soup_kitchen' },
        { name: 'Dîner Carb-Load', description: 'Lasagnes végétariennes à la ricotta et épinards.', icon: 'dinner_dining' },
        { name: 'Dîner Grill-Master', description: 'Brochettes de poulet au citron, taboulé de chou-fleur.', icon: 'dinner_dining' },
        { name: 'Dîner Night-Fuel', description: 'Omelette aux champignons des bois et salade de jeunes pousses.', icon: 'soup_kitchen' },
      ],
    };

    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    
    // Mélange des listes pour garantir la variété
    const breakfasts = [...mealLibrary.breakfasts].sort(() => Math.random() - 0.5);
    const lunches = [...mealLibrary.lunches].sort(() => Math.random() - 0.5);
    const snacks = [...mealLibrary.snacks].sort(() => Math.random() - 0.5);
    const dinners = [...mealLibrary.dinners].sort(() => Math.random() - 0.5);

    return {
      userId,
      weekNumber: 1,
      days: days.map((day, index) => {
        const isMatchDay = index === 5; // Samedi
        const isRecoveryDay = index === 6 || index === 2; // Mercredi et Dimanche
        
        // Multiplicateur IA d'intensité (1.8 Match, 1.5 Entraînement, 1.2 Repos)
        const intensityMult = isMatchDay ? 1.8 : (isRecoveryDay ? 1.2 : 1.5);
        const dailyKcal = Math.round(bmr * intensityMult);
        
        // Utilisation d'un repas différent par jour de la semaine (index 0 à 6)
        const bFast = breakfasts[index % breakfasts.length];
        const lunch = lunches[index % lunches.length];
        const snack = snacks[index % snacks.length];
        const dinner = dinners[index % dinners.length];
        
        return {
          day,
          totalKcal: dailyKcal,
          advice: isMatchDay ? 
            "JOUR DE MATCH : Augmentation glycémique 3h avant le coup d'envoi. Focus sur l'explosivité." : 
            isRecoveryDay ? "JOUR DE REPOS : Réduction calorique et hydratation maximale." : 
            "ENTRAÎNEMENT : Apport stable pour soutenir la charge de travail tactique.",
          meals: [
            {
              ...bFast,
              kcal: Math.round(dailyKcal * 0.25),
              carbs: Math.round(profile.weightKg * (isMatchDay ? 1.8 : 1.3)),
              proteins: Math.round(profile.weightKg * 0.5),
              fats: Math.round(profile.weightKg * 0.2),
            },
            {
              ...lunch,
              kcal: Math.round(dailyKcal * 0.35),
              carbs: Math.round(profile.weightKg * (isMatchDay ? 2.8 : 2.0)),
              proteins: Math.round(profile.weightKg * 0.6),
              fats: Math.round(profile.weightKg * 0.3),
            },
            {
              ...snack,
              kcal: Math.round(dailyKcal * 0.15),
              carbs: Math.round(profile.weightKg * 0.8),
              proteins: Math.round(profile.weightKg * 0.3),
              fats: Math.round(profile.weightKg * 0.1),
            },
            {
              ...dinner,
              kcal: Math.round(dailyKcal * 0.25),
              carbs: Math.round(profile.weightKg * (isMatchDay ? 1.5 : 1.0)),
              proteins: Math.round(profile.weightKg * 0.6),
              fats: Math.round(profile.weightKg * 0.2),
            }
          ]
        };
      })
    };
  }
}
