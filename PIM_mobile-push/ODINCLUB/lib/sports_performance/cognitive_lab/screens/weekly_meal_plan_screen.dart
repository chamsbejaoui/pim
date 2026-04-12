import 'package:flutter/material.dart';
import '../models/nutrition_models.dart';
import '../services/nutrition_api_service.dart';

class WeeklyMealPlanScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const WeeklyMealPlanScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<WeeklyMealPlanScreen> createState() => _WeeklyMealPlanScreenState();
}

class _WeeklyMealPlanScreenState extends State<WeeklyMealPlanScreen> {
  final NutritionApiService _api = NutritionApiService();
  WeeklyMealPlan? _weeklyPlan;
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadWeeklyPlan();
  }

  Future<void> _loadWeeklyPlan() async {
    setState(() => _isLoading = true);
    final plan = await _api.getWeeklyMealPlan(widget.playerId);
    setState(() {
      _weeklyPlan = plan;
      _isLoading = false;
    });
  }

  Future<void> _generateAiPlan() async {
    setState(() => _isGenerating = true);
    // Simule un temps de "réflexion" de l'IA pour renforcer l'aspect premium
    await Future.delayed(const Duration(seconds: 2));
    final plan = await _api.generateAiWeeklyPlan(widget.playerId);
    
    if (mounted) {
      if (plan != null) {
        setState(() {
          _weeklyPlan = plan;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Programme généré par l\'IA avec succès ! ✓', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      } else {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Erreur lors de la génération IA.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_isLoading || _isGenerating)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isGenerating) ...[
                      const _AiPulsingIcon(),
                      const SizedBox(height: 24),
                      const Text('IA EN TRAIN DE GÉNÉRER...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const Text('OPTIMISATION DES MACROS EN COURS', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, letterSpacing: 1)),
                    ] else
                      const CircularProgressIndicator(color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _weeklyPlan != null) ...[
            _buildDaySelector(),
            _buildDailyContent(),
          ],
          if (!_isLoading && _weeklyPlan == null)
            const SliverFillRemaining(child: Center(child: Text('Erreur lors du chargement du plan.', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROGRAMME NUTRITIONNEL', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(widget.playerName.toUpperCase(), style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
      actions: [
        if (!_isLoading && !_isGenerating)
          TextButton.icon(
            onPressed: _generateAiPlan,
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 18),
            label: const Text('IA GEN', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDaySelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _weeklyPlan!.days.length,
          itemBuilder: (context, index) {
            final dayPlan = _weeklyPlan!.days[index];
            final isSelected = _selectedDayIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayPlan.day.substring(0, 3).toUpperCase(), 
                      style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDailyContent() {
    final dayPlan = _weeklyPlan!.days[_selectedDayIndex];
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildDailySummary(dayPlan),
          const SizedBox(height: 24),
          const Text('VOTRE MENU DU JOUR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...dayPlan.meals.map((meal) => _buildMealCard(meal)),
          const SizedBox(height: 24),
          _buildAdviceSection(dayPlan.advice),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildDailySummary(DailyMealPlan day) {
    bool isMatch = day.advice.contains('MATCH');
    bool isRecovery = day.advice.contains('REPOS');
    Color intensityColor = isMatch ? Colors.redAccent : (isRecovery ? const Color(0xFF3B82F6) : const Color(0xFF10B981));
    String intensityLabel = isMatch ? 'HAUTE INTENSITÉ (MATCH)' : (isRecovery ? 'RÉCUPÉRATION' : 'ENTRAÎNEMENT TACTIQUE');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: intensityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt, color: intensityColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OBJECTIF CALORIQUE TOTAL', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${day.totalKcal.toStringAsFixed(0)} KCAL', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: intensityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: intensityColor.withOpacity(0.2)),
                ),
                child: Text(
                  intensityLabel,
                  style: TextStyle(color: intensityColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealPlan meal) {
    IconData getIcon(String iconStr) {
      switch(iconStr) {
        case 'breakfast_dining': return Icons.coffee;
        case 'lunch_dining': return Icons.lunch_dining;
        case 'dinner_dining': return Icons.ramen_dining;
        case 'fitness_center': return Icons.fitness_center;
        case 'egg': return Icons.egg_alt_outlined;
        case 'cake': return Icons.cake_outlined;
        case 'restaurant': return Icons.restaurant;
        case 'ramen_dining': return Icons.ramen_dining;
        case 'apple': return Icons.apple;
        case 'local_drink': return Icons.local_drink;
        case 'soup_kitchen': return Icons.soup_kitchen;
        default: return Icons.fastfood;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(getIcon(meal.icon), color: const Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('${meal.kcal.toStringAsFixed(0)} KCAL', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(meal.description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMacroInfo('PROTEIN', '${meal.proteins.toStringAsFixed(0)}g', const Color(0xFF10B981)),
              _buildMacroInfo('CARBS', '${meal.carbs.toStringAsFixed(0)}g', const Color(0xFFF59E0B)),
              _buildMacroInfo('FATS', '${meal.fats.toStringAsFixed(0)}g', const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection(String advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONSEIL DU COACH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 4),
                Text(advice, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPulsingIcon extends StatefulWidget {
  const _AiPulsingIcon();

  @override
  State<_AiPulsingIcon> createState() => _AiPulsingIconState();
}

class _AiPulsingIconState extends State<_AiPulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.1 + (0.2 * _controller.value)),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3 * _controller.value),
                blurRadius: 20,
                spreadRadius: 10 * _controller.value,
              )
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 40),
        );
      },
    );
  }
}
