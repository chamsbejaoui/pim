import { Injectable } from '@nestjs/common';
import { NutritionLabService } from './nutrition-lab.service';
import { CognitiveLabService } from '../../cognitive-lab/services/cognitive-lab.service';

@Injectable()
export class MetabolicAiService {
  constructor(
    private nutritionLabService: NutritionLabService,
    private cognitiveLabService: CognitiveLabService
  ) {}

  async getDailyMetabolicStatus(userId: string) {
    const profile = await this.nutritionLabService.getPhysicalProfile(userId);
    const nutritionLogs = await this.nutritionLabService.getTodaysNutritionLogs(userId);
    
    // 1. CALCULS BIOMÉTRIQUES SCIENTIFIQUES
    let graissePercent: number | null = null;
    let masseMuscul: number | null = null;
    let bmr: number | null = null;
    let age: number | null = null;
    let eauBase: number | null = null;
    let eauEntrainement: number | null = null;
    let eauMatch: number | null = null;
    let error: string | null = null;

    if (profile.tourTaille && profile.tourCou && profile.dateNaissance) {
      const diff = profile.tourTaille - profile.tourCou;
      
      // Validation du différentiel de mesure (US Navy logic)
      if (diff <= 5) {
        error = "Données de mesure incohérentes — vérifier tourTaille";
      } else {
        // Formule US Navy (Hommes)
        const logTaille = Math.log10(profile.heightCm);
        const logDiff = Math.log10(diff);
        const graisseRaw = 495 / (1.0324 - 0.19077 * logDiff + 0.15456 * logTaille) - 450;
        
        // Clamp physiologique : jamais < 3% ni > 40% pour un athlète
        graissePercent = Math.max(3, Math.min(40, graisseRaw));
        graissePercent = Math.round(graissePercent * 10) / 10;

        // Masse musculaire estimée (Lean mass * coefficient pro 0.85)
        masseMuscul = profile.weightKg * (1 - graissePercent / 100) * 0.85;
        
        // Validation finale masse
        if (masseMuscul > profile.weightKg) {
            masseMuscul = profile.weightKg * 0.7; // Fallback sécurisant
            error = "Composition calculée impossible — vérifier les données";
        }
        masseMuscul = Math.round(masseMuscul * 10) / 10;

        // Âge et BMR (Mifflin-St Jeor)
        const birthDate = new Date(profile.dateNaissance);
        age = new Date().getFullYear() - birthDate.getFullYear();
        bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * age) + 5;
        bmr = Math.round(bmr);

        // Hydratation adaptive (L)
        eauBase = Math.round(profile.weightKg * 0.035 * 100) / 100;
        eauEntrainement = Math.round((eauBase + 0.8) * 100) / 100;
        eauMatch = Math.round((eauBase + 1.5) * 100) / 100;
      }
    }

    if (!bmr) {
      // Fallback simple si données manquantes ou calcul échoué
      bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) + 500;
      if (!error && (!profile.tourTaille || !profile.tourCou)) {
        error = "Données incomplètes pour calcul précis";
      }
    }

    // 2. SYNCHRONISATION AVEC L'INTENSITÉ DU JOUR (IA)
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    const now = new Date();
    const dayName = days[now.getDay()];
    const dayIndex = now.getDay(); // 0 is Sunday, 6 is Saturday

    const isMatchDay = dayIndex === 6; // Samedi
    const isRecoveryDay = dayIndex === 0 || dayIndex === 3; // Dimanche et Mercredi
    
    // Multiplicateur IA d'intensité (1.8 Match, 1.5 Entraînement, 1.2 Repos)
    const intensityMult = isMatchDay ? 1.8 : (isRecoveryDay ? 1.2 : 1.5);
    
    let targetCalories = (bmr || 2000) * intensityMult;
    let targetCarbs = profile.weightKg * (isMatchDay ? 6.9 : (isRecoveryDay ? 3.5 : 5.1));
    let targetProteins = profile.weightKg * 2.0; // Protéines stables ~2g/kg
    let targetHydration = (isMatchDay ? (eauMatch || 3.5) : (isRecoveryDay ? (eauBase || 2.2) : (eauEntrainement || 2.8))) * 1000; // ml
    
    let cognitiveFatigueDetected = false;

    // Logique BRAIN DRAIN (Surplus glycémique si fatigue mentale)
    try {
      const baseline = await this.cognitiveLabService.getBaseline(userId);
      const dashboard = await this.cognitiveLabService.getPlayerDashboard(userId);
      const history = dashboard.history || [];
      const todaySessions = history.filter(s => {
        const d = new Date(s.date);
        return d.toDateString() === now.toDateString() && s.mentalScore;
      });

      if (todaySessions.length > 0 && baseline && baseline.mentalScore > 0) {
        const todaysMentalAvg = todaySessions.reduce((acc, curr) => acc + (curr.mentalScore || 0), 0) / todaySessions.length;
        if (todaysMentalAvg < baseline.mentalScore * 0.85) {
            cognitiveFatigueDetected = true;
            targetCarbs *= 1.20; // +20% Brain fuel
            targetCalories += (targetCarbs * 0.2 * 4); // Ajustement calories
        }
      }
    } catch (e) {
      console.log('No cognitive data found or error calculating brain drain:', e);
    }

    // 3. CALCUL DES CONSOMMÉS
    const ingestedCarbs = (nutritionLogs || []).reduce((sum, log) => sum + log.carbsGrams, 0);
    const ingestedProteins = (nutritionLogs || []).reduce((sum, log) => sum + log.proteinsGrams, 0);
    const ingestedHydration = (nutritionLogs || []).reduce((sum, log) => sum + log.hydrationMl, 0);

    return {
      profileData: {
        ...profile.toObject(),
        graissePercent,
        masseMuscul,
        age,
        bmr,
        eauBase,
        eauEntrainement,
        eauMatch,
        intensityLabel: isMatchDay ? 'MATCH' : (isRecoveryDay ? 'REPOS' : 'ENTRAÎNEMENT')
      },
      error,
      cognitiveFatigueDetected,
      alertMessage: cognitiveFatigueDetected ? 
        "⚠️ Fatigue Cognitive détectée. Le SNC est épuisé. Augmentation des glucides (+20%) pour la résynthèse." :
        (error ? `❌ Alerte Données : ${error}` : `✅ Statut stable pour un jour de ${isMatchDay ? 'MATCH' : (isRecoveryDay ? 'REPOS' : 'TRAINING')}.`),
      targets: {
          carbs: Math.round(targetCarbs),
          proteins: Math.round(targetProteins),
          hydrationMl: Math.round(targetHydration),
          calories: Math.round(targetCalories)
      },
      current: {
          carbs: ingestedCarbs,
          proteins: ingestedProteins,
          hydrationMl: ingestedHydration
      },
      deficits: {
          carbs: Math.max(0, Math.round(targetCarbs - ingestedCarbs)),
          proteins: Math.max(0, Math.round(targetProteins - ingestedProteins)),
          hydrationMl: Math.max(0, Math.round(targetHydration - ingestedHydration))
      }
    };
  }
}
