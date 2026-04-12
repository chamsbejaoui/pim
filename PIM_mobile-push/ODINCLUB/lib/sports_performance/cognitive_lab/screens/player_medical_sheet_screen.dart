import 'dart:math';
import 'package:flutter/material.dart';
import '../models/nutrition_models.dart';
import '../services/nutrition_api_service.dart';

class PlayerMedicalSheetScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String playerPosition;

  const PlayerMedicalSheetScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerPosition,
  });

  @override
  State<PlayerMedicalSheetScreen> createState() => _PlayerMedicalSheetScreenState();
}

class _PlayerMedicalSheetScreenState extends State<PlayerMedicalSheetScreen>
    with SingleTickerProviderStateMixin {
  final NutritionApiService _api = NutritionApiService();
  late AnimationController _animController;

  PhysicalProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _showSuccess = false;

  // Form values (doubles for sliders)
  double _currentWeight = 75.0;
  double _currentHeight = 180.0;
  double _currentWaist = 80.0;
  double _currentNeck = 38.0;
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _selectedPosition = 'Midfielder';

  // Calculated values for realtime display
  double _localBmi = 0;
  double _localFat = 0;
  double _localMuscle = 0;
  double _localWater = 0;
  int _localBmr = 0;

  MetabolicStatus? _metabolicStatus;

  final List<String> _positions = [
    'Goalkeeper', 'Defender', 'Midfielder', 'Forward'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _api.getPhysicalProfile(widget.playerId);
    final status = await _api.getMetabolicStatus(widget.playerId);
    
    setState(() {
      _profile = profile;
      _metabolicStatus = status;
      _isLoading = false;
      if (profile != null) {
        _currentWeight = profile.weightKg;
        _currentHeight = profile.heightCm;
        _currentWaist = profile.tourTaille;
        _currentNeck = profile.tourCou;
        _birthDate = profile.dateNaissance;
        _selectedPosition = profile.position;
        _calculateLocalStatus();
      }
      _animController.forward();
    });
  }

  void _calculateLocalStatus() {
    // 1. BMI
    _localBmi = _currentWeight / (pow(_currentHeight / 100, 2));

    // 2. Body Fat (US Navy)
    double log10(double x) => log(x) / ln10;
    double diff = _currentWaist - _currentNeck;
    if (diff > 5) {
      double logTaille = log10(_currentHeight);
      double logDiff = log10(diff);
      double graisseRaw = 495 / (1.0324 - 0.19077 * logDiff + 0.15456 * logTaille) - 450;
      _localFat = graisseRaw.clamp(3, 40);
    } else {
      _localFat = 0;
    }

    // 3. Muscle Mass (0.85 pro athlete coefficient)
    _localMuscle = _currentWeight * (1 - _localFat / 100) * 0.85;

    // 4. BMR (Mifflin-St Jeor)
    int age = DateTime.now().year - _birthDate.year;
    _localBmr = ((10 * _currentWeight) + (6.25 * _currentHeight) - (5 * age) + 5).round();

    // 5. Water (Base 0.035L/kg)
    _localWater = _currentWeight * 0.035;
  }

  Future<void> _saveProfile() async {
    final profile = PhysicalProfile(
      userId: widget.playerId,
      weightKg: _currentWeight,
      heightCm: _currentHeight,
      tourTaille: _currentWaist,
      tourCou: _currentNeck,
      dateNaissance: _birthDate,
      position: _selectedPosition,
    );

    setState(() {
      _isSaving = true;
      _showSuccess = false;
    });

    try {
      final error = await _api.savePhysicalProfile(profile);

      if (error == null) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _showSuccess = true;
        });
        
        // Show success animation for 2 seconds
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) setState(() => _showSuccess = false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fiche médicale sauvegardée ✓'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadProfile();
      } else if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERREUR : $error'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERREUR RÉSEAU : $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          image: DecorationImage(
            image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
            opacity: 0.03,
            repeat: ImageRepeat.repeat
          )
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  if (_isLoading) _buildSkeleton(),
                  if (!_isLoading && _profile == null && !_isEditing) _buildEmptyState(),
                  if (!_isLoading && (_profile != null || _isEditing)) ...[
                    FadeTransition(
                      opacity: _animController,
                      child: Column(
                        children: [
                          if (_metabolicStatus?.error != null) _buildDataConsistencyAlert(_metabolicStatus!.error!),
                          _buildPhysicalStats(),
                          const SizedBox(height: 24),
                          _buildBodyCompositionRings(),
                          const SizedBox(height: 24),
                          _buildEditForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.playerName.isNotEmpty
                              ? widget.playerName.substring(0, min(2, widget.playerName.length)).toUpperCase()
                              : 'JR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.playerName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                                ),
                                child: Text(
                                  widget.playerPosition,
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '• FICHE BIOMÉTRIQUE',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isLoading && _profile != null)
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.tune, color: _isEditing ? Colors.redAccent : const Color(0xFF10B981)),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
      ],
    );
  }

  Widget _buildPhysicalStats() {
    if (_profile == null) return const SizedBox.shrink();

    final bmi = _profile!.bmi;
    String bmiStatus;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiStatus = 'DÉFICIT PONDÉRAL';
      bmiColor = Colors.orangeAccent;
    } else if (bmi < 25) {
      bmiStatus = 'ATHLÈTE OPTIMAL';
      bmiColor = const Color(0xFF10B981);
    } else if (bmi < 30) {
      bmiStatus = 'SURPOIDS LÉGER';
      bmiColor = Colors.orangeAccent;
    } else {
      bmiStatus = 'RISQUE MÉTABOLIQUE';
      bmiColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PARAMÈTRES PHYSIQUES', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, decoration: TextDecoration.none)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('MASSE TOTALE', _profile!.weightKg.toStringAsFixed(1), 'KG', const Color(0xFF3B82F6), Icons.scale)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('STATURE', _profile!.heightCm.toStringAsFixed(1), 'CM', const Color(0xFF8B5CF6), Icons.height)),
          ],
        ),
        const SizedBox(height: 12),
        _buildBmiCard(bmi, bmiStatus, bmiColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, decoration: TextDecoration.none)),
              Icon(icon, color: color.withOpacity(0.5), size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard(double bmi, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), const Color(0xFF1E293B).withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.analytics_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IMC / INDICE DE MASSE CORPORELLE', style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, decoration: TextDecoration.none)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(bmi.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5, decoration: TextDecoration.none)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataConsistencyAlert(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionRings() {
    if (_profile == null) return const SizedBox.shrink();
    
    // Utilisation des données calculées par le backend si disponibles
    final profileWithCalculations = _metabolicStatus?.profileData ?? _profile!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMPOSITION TISSULAIRE (IA ESTIMATE)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, decoration: TextDecoration.none)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildRingCard('MUSCLE', profileWithCalculations.masseMuscul ?? 0, profileWithCalculations.weightKg, 'KG', const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildRingCard(
              'GRASSE', 
              _metabolicStatus?.error != null ? 0 : (profileWithCalculations.graissePercent ?? 0), 
              100, 
              '%', 
              _metabolicStatus?.error != null ? Colors.orange : const Color(0xFFF59E0B),
              showNoValue: _metabolicStatus?.error != null
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildRingCard('EAU', (_metabolicStatus?.targets['hydrationMl'] ?? 0) / 1000, 5, 'L', const Color(0xFF3B82F6))),
          ],
        ),
      ],
    );
  }

  Widget _buildRingCard(String label, double value, double max, String unit, Color color, {bool showNoValue = false}) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: showNoValue ? 0 : pct,
                  strokeWidth: 4,
                  backgroundColor: color.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showNoValue ? '—' : value.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
                    ),
                    Text(
                      unit,
                      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, decoration: TextDecoration.none),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    if (!_isEditing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ÉDITION DU PROFIL ATHLÈTE', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, decoration: TextDecoration.none)),
              IconButton(onPressed: () => setState(() => _isEditing = false), icon: const Icon(Icons.close, color: Colors.white30, size: 18))
            ],
          ),
          const SizedBox(height: 32),
          
          _buildSliderField(
            'Poids (KG)', 
            _currentWeight, 
            50, 120, 
            (val) => setState(() { _currentWeight = val; _calculateLocalStatus(); }),
            'kg', 'Glissez pour modifier', const Color(0xFF10B981)
          ),
          
          _buildSliderField(
            'Taille (CM)', 
            _currentHeight, 
            155, 210, 
            (val) => setState(() { _currentHeight = val; _calculateLocalStatus(); }),
            'cm', '', const Color(0xFF3B82F6)
          ),
          
          _buildSliderField(
            'Tour de taille (CM)', 
            _currentWaist, 
            60, 120, 
            (val) => setState(() { _currentWaist = val; _calculateLocalStatus(); }),
            'cm', 'Mesuré au niveau du nombril', Colors.orangeAccent
          ),
          
          _buildSliderField(
            'Tour de cou (CM)', 
            _currentNeck, 
            30, 55, 
            (val) => setState(() { _currentNeck = val; _calculateLocalStatus(); }),
            'cm', 'À la base du cou', Colors.purpleAccent
          ),

          const SizedBox(height: 8),
          
          // Date of birth picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _birthDate = picked;
                  _calculateLocalStatus();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE DE NAISSANCE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        "${_birthDate.day}/${_birthDate.month}/${_birthDate.year}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          ),

          DropdownButtonFormField<String>(
            value: _selectedPosition,
            dropdownColor: const Color(0xFF1E293B),
            icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
            decoration: InputDecoration(
              labelText: 'POSTE SUR LE TERRAIN',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onChanged: (val) => setState(() => _selectedPosition = val ?? 'Midfielder'),
            items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
          ),

          const SizedBox(height: 40),
          const Text('Calculé automatiquement par l\'IA', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          
          _buildIAStatusGrid(),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _showSuccess ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: (_showSuccess ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else if (_showSuccess)
                  const Icon(Icons.check, size: 24)
                else
                  const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: 12),
                Text(
                  _isSaving ? 'SAUVEGARDE EN COURS...' : (_showSuccess ? 'DONNÉES SÉCURISÉES' : 'SÉCURISER LES DONNÉES'), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5, decoration: TextDecoration.none)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField(String label, double value, double min, double max, Function(double) onChanged, String unit, String help, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(unit, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: color,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            overlayColor: color.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, pressedElevation: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (val) => onChanged(val),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toInt()} $unit', style: const TextStyle(color: Color(0xFF475569), fontSize: 9, fontWeight: FontWeight.bold)),
              if (help.isNotEmpty)
                Text(help, style: const TextStyle(color: Color(0xFF475569), fontSize: 9, fontWeight: FontWeight.bold)),
              Text('${max.toInt()} $unit', style: const TextStyle(color: Color(0xFF475569), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIAStatusGrid() {
    String fatStatus;
    if (_localBmi < 18.5) fatStatus = 'Déficit';
    else if (_localBmi < 25) fatStatus = 'Optimal';
    else fatStatus = 'Surpoids';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRealtimeCard('IMC', _localBmi.toStringAsFixed(1), fatStatus, const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildRealtimeCard('% Graisse', '${_localFat.toStringAsFixed(1)}%', 'US Navy', Colors.orangeAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRealtimeCard('Muscle', '${_localMuscle.toStringAsFixed(1)} kg', 'estimé', const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildRealtimeCard('Eau repos', '${_localWater.toStringAsFixed(2)} L', '/ jour', Colors.purpleAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildRealtimeCard(String label, String value, String subValue, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subValue, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.person_add_outlined, color: Color(0xFF64748B), size: 40),
          ),
          const SizedBox(height: 32),
          const Text('INITIALISATION REQUISE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, decoration: TextDecoration.none)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Les paramètres biométriques sont nécessaires pour calibrer les algorithmes nutritionnels.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.5, decoration: TextDecoration.none),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CRÉER LA FICHE BIOMÉTRIQUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
      )),
    );
  }

  Widget _buildFab() {
    return const SizedBox.shrink();
  }
}
