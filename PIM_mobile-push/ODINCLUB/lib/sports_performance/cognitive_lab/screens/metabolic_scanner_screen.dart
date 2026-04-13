import 'package:flutter/material.dart';
import '../models/nutrition_models.dart';
import '../services/nutrition_api_service.dart';
import 'weekly_meal_plan_screen.dart';

class MetabolicScannerScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const MetabolicScannerScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<MetabolicScannerScreen> createState() => _MetabolicScannerScreenState();
}

class _MetabolicScannerScreenState extends State<MetabolicScannerScreen>
    with TickerProviderStateMixin {
  final NutritionApiService _api = NutritionApiService();
  MetabolicStatus? _status;
  bool _isLoading = true;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _mealTemplates = [
    {
      'label': 'Repas Pré-Match',
      'subtitle': '80g Glucides · 40g Protéines',
      'icon': Icons.sports_soccer,
      'color': const Color(0xFF10B981),
      'type': MealType.preMatch,
      'carbs': 80.0, 'proteins': 40.0, 'fats': 15.0, 'hydration': 500.0,
    },
    {
      'label': 'Shake Récupération',
      'subtitle': '30g Glucides · 50g Protéines (Whey)',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF3B82F6),
      'type': MealType.postMatchRecovery,
      'carbs': 30.0, 'proteins': 50.0, 'fats': 5.0, 'hydration': 300.0,
    },
    {
      'label': 'Veille de Match',
      'subtitle': '120g Glucides · 35g Protéines',
      'icon': Icons.nightlight_outlined,
      'color': const Color(0xFF8B5CF6),
      'type': MealType.highCarb,
      'carbs': 120.0, 'proteins': 35.0, 'fats': 20.0, 'hydration': 400.0,
    },
    {
      'label': 'Hydratation Intensive',
      'subtitle': '1000ml eau · Électrolytes',
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFF06B6D4),
      'type': MealType.hydration,
      'carbs': 0.0, 'proteins': 0.0, 'fats': 0.0, 'hydration': 1000.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final status = await _api.getMetabolicStatus(widget.playerId);
    setState(() {
      _status = status;
      _isLoading = false;
    });
  }
  //C'est le verrou de sécurité qui compare votre consommation actuelle aux objectifs IA avant d'autoriser un repa
  bool _canLog(Map<String, dynamic> template) {
    if (_status == null) return false;
    final type = template['type'] as MealType;

    if (type == MealType.hydration) {
      return (_status!.current['hydrationMl'] ?? 0) < (_status!.targets['hydrationMl'] ?? 1);
    }

    // Pour les autres repas, si le besoin en Glucides ET Protéines est comblé, on bloque
    final bool carbsMet = (_status!.current['carbs'] ?? 0) >= (_status!.targets['carbs'] ?? 1);
    final bool protMet = (_status!.current['proteins'] ?? 0) >= (_status!.targets['proteins'] ?? 1);

    return !carbsMet || !protMet;
  }

  Future<void> _quickLog(Map<String, dynamic> template) async {
    if (!_canLog(template)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF59E0B),
          content: Text('Objectif déjà atteint ! Vos besoins sont comblés.', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
        ),
      );
      return;
    }

    final MealType mealType = template['type'] as MealType;
    final log = NutritionLog(
      userId: widget.playerId,
      mealType: mealType.value,
      carbsGrams: template['carbs'] as double,
      proteinsGrams: template['proteins'] as double,
      fatsGrams: template['fats'] as double,
      hydrationMl: template['hydration'] as double,
    );

    final success = await _api.logNutrition(log);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${template['label']} enregistré !', style: const TextStyle(color: Colors.white, decoration: TextDecoration.none)),
            ],
          ),
        ),
      );
      _loadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanner Métabolique', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
            Text(widget.playerName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, decoration: TextDecoration.none)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _status == null
          ? _buildNoProfileState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2 * _pulseController.value),
                        blurRadius: 30,
                        spreadRadius: 10 * _pulseController.value,
                      )
                    ],
                  ),
                ),
              ),
              const Icon(Icons.biotech_outlined, color: Color(0xFF10B981), size: 48),
              // Scanning line effect
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Positioned(
                    top: 10 + (100 * _pulseController.value),
                    child: Container(
                      width: 100,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF10B981),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text('INITIALISATION DU SCAN...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, decoration: TextDecoration.none)),
          const SizedBox(height: 8),
          const Text('ANALYSE DES RÉSERVES DE GLYCOGÈNE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, letterSpacing: 1, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, color: Color(0xFF475569), size: 60),
          const SizedBox(height: 16),
          const Text('Fiche Physique Requise', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          const SizedBox(height: 8),
          const Text('Créez d\'abord la fiche médicale du joueur.', style: TextStyle(color: Color(0xFF64748B), decoration: TextDecoration.none)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Retour à la Fiche'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final bool isEmpty = (_status!.current['carbs'] ?? 0) == 0 &&
        (_status!.current['proteins'] ?? 0) == 0 &&
        (_status!.current['hydrationMl'] ?? 0) == 0;

    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          image: DecorationImage(
              image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
              opacity: 0.05,
              repeat: ImageRepeat.repeat
          )
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildPremiumHeader(),
            const SizedBox(height: 24),
            _buildAlertBanner(),
            const SizedBox(height: 24),
            if (isEmpty) _buildEmptyDailyState(),
            _buildMacroTargets(),
            const SizedBox(height: 24),
            _buildQuickLogs(),
            const SizedBox(height: 24),
            _buildDeficitsPanel(),
            const SizedBox(height: 24),
            _buildWeeklyPlanButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDailyState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_outlined, color: Color(0xFF3B82F6), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'EN ATTENTE DE DONNÉES',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun repas enregistré aujourd\'hui — commencez votre suivi ci-dessous.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.5, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B).withOpacity(0.8),
            const Color(0xFF0F172A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATUS SYSTÉMIQUE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, decoration: TextDecoration.none)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _status!.cognitiveFatigueDetected ? Colors.redAccent : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_status!.cognitiveFatigueDetected ? Colors.redAccent : const Color(0xFF10B981)).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _status!.cognitiveFatigueDetected ? 'ALERTE FATIGUE' : 'OPTI-PERFORMANCE',
                    style: TextStyle(
                      color: _status!.cognitiveFatigueDetected ? Colors.redAccent : const Color(0xFF10B981),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.bolt, color: Colors.yellowAccent, size: 20),
              const SizedBox(height: 4),
              Text(
                '${_status!.targets['calories'] ?? 0}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
              ),
              const Text('KCAL / JOUR', style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final isCritical = _status!.cognitiveFatigueDetected;
    final color = isCritical ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isCritical ? Icons.warning_amber_rounded : Icons.psychology_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(width: 4, color: color)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _status!.alertMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTargets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BILAN NUTRITIONNEL', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, decoration: TextDecoration.none)),
            const Icon(Icons.analytics_outlined, color: Color(0xFF64748B), size: 16),
          ],  //Calcul du ratio de précision
        ),
        const SizedBox(height: 16),
        _buildMacroBar('GLUCIDES (ENERGY)', _status!.current['carbs'] ?? 0, _status!.targets['carbs'] ?? 1, 'G', const Color(0xFFF59E0B)),
        const SizedBox(height: 12),
        _buildMacroBar('PROTÉINES (REPAIR)', _status!.current['proteins'] ?? 0, _status!.targets['proteins'] ?? 1, 'G', const Color(0xFF10B981)),
        const SizedBox(height: 12),
        _buildMacroBar('HYDRATATION (FLOW)', _status!.current['hydrationMl'] ?? 0, _status!.targets['hydrationMl'] ?? 1, 'ML', const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildMacroBar(String label, double current, double target, String unit, Color color) {
    String displayCurrent = current.toStringAsFixed(0);
    String displayTarget = target.toStringAsFixed(0);
    String displayUnit = unit;

    if (unit == 'ML' && target > 999) {
      displayCurrent = (current / 1000).toStringAsFixed(1);
      displayTarget = (target / 1000).toStringAsFixed(1);
      displayUnit = 'L';
    }

    final double ratio = current / (target > 0 ? target : 1);
    final double pct = ratio.clamp(0.0, 1.0);
    final bool isCompleted = ratio >= 1.0;
    final bool isExcess = ratio > 1.05; // Marge de 5% avant l'alerte
    final int percentage = (ratio * 100).round();

    final Color barColor = isExcess ? const Color(0xFFEF4444) : color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          border: isCompleted ? Border.all(color: barColor.withOpacity(0.3), width: 1.5) : null,
        ),
        child: Stack(
          children: [
            // Progress background
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      barColor.withOpacity(0.1),
                      isCompleted ? barColor.withOpacity(0.4) : barColor.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
            ),
            // Success Glow
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: barColor.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)
                    ],
                  ),
                ),
              ),
            // Progress thin line
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                alignment: Alignment.bottomLeft,
                widthFactor: pct,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: barColor,
                    boxShadow: [
                      if (isCompleted) BoxShadow(color: barColor.withOpacity(0.8), blurRadius: 10)
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, decoration: TextDecoration.none)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$displayCurrent $displayUnit',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: TextStyle(color: isExcess ? const Color(0xFFEF4444) : (isCompleted ? color : const Color(0xFF475569)), fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: isExcess ? const Color(0xFFEF4444) : color, shape: BoxShape.circle),
                          child: Icon(isExcess ? Icons.warning_amber_rounded : Icons.check, color: Colors.black, size: 12),
                        )
                      else
                        Text(isExcess ? 'EXCÈS !' : 'OBJECTIF', style: TextStyle(color: isExcess ? const Color(0xFFEF4444) : color.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                      const SizedBox(height: 4),
                      Text('$displayTarget $displayUnit', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('LOGGING RAPIDE (TEMPLATES)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, decoration: TextDecoration.none)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: _mealTemplates.length,
          itemBuilder: (context, index) {
            final tmpl = _mealTemplates[index];
            final color = tmpl['color'] as Color;
            final bool canLog = _canLog(tmpl);

            return Opacity(
              opacity: canLog ? 1.0 : 0.4,
              child: InkWell(
                onTap: () => _quickLog(tmpl),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: canLog ? color.withOpacity(0.15) : Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tmpl['icon'] as IconData, color: canLog ? color : const Color(0xFF64748B), size: 24),
                      const SizedBox(height: 12),
                      Text(
                        tmpl['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: canLog ? Colors.white : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 4),
                      if (canLog)
                        Text(
                          tmpl['type'] == MealType.hydration
                              ? (tmpl['hydration'] >= 1000
                              ? '${(tmpl['hydration'] / 1000).toStringAsFixed(1).replaceAll('.0', '')}L'
                              : '${tmpl['hydration'].toStringAsFixed(0)}ml')
                              : '${tmpl['carbs'].toStringAsFixed(0)}g Carbs',
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                        )
                      else
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 10),
                            SizedBox(width: 4),
                            Text('COMPLET', style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeficitsPanel() {
    final carbDef = _status!.deficits['carbs'] ?? 0;
    final protDef = _status!.deficits['proteins'] ?? 0;
    final hydDef = _status!.deficits['hydrationMl'] ?? 0;

    if (carbDef == 0 && protDef == 0 && hydDef == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.stars, color: Color(0xFF10B981), size: 32),
            const SizedBox(height: 12),
            const Text(
              'RÉSERVES OPTIMALES',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 4),
            Text(
              'Prêt pour haute intensité.',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, decoration: TextDecoration.none),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DÉFICITS À COMBLER (ALGORITHME)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, decoration: TextDecoration.none)),
        const SizedBox(height: 16),
        if (carbDef > 0) _buildDeficitChip('GLUCIDES', carbDef, 'G', const Color(0xFFF59E0B), 'COMPLEXE (RIZ/PÂTES)'),
        if (protDef > 0) _buildDeficitChip('PROTÉINES', protDef, 'G', const Color(0xFF10B981), 'REPAIR (WHEY/VIANDE BLANCHE)'),
        if (hydDef > 0) _buildDeficitChip('HYDRATATION', hydDef, 'ML', const Color(0xFF3B82F6), 'EAU + ÉLECTROLYTES'),
      ],
    );
  }

  Widget _buildDeficitChip(String label, double value, String unit, Color color, String tip) {
    String displayValue = value.toStringAsFixed(0);
    String displayUnit = unit;

    if (unit == 'ML' && value > 999) {
      displayValue = (value / 1000).toStringAsFixed(1);
      displayUnit = 'L';
    } else if (unit == 'ML') {
      displayValue = value.toStringAsFixed(0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, decoration: TextDecoration.none)),
              const SizedBox(height: 2),
              Text(tip, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '-$displayValue $displayUnit',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeeklyMealPlanScreen(
                playerId: widget.playerId,
                playerName: widget.playerName,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_week, size: 24),
            SizedBox(width: 12),
            Text(
              'CONSULTER LE PROGRAMME HEBDOMADAIRE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
