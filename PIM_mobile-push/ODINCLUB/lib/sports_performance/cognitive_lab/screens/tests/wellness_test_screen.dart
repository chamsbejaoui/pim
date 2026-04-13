import 'package:flutter/material.dart';
import 'dart:ui';

class WellnessTestScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> results) onComplete;
  const WellnessTestScreen({super.key, required this.onComplete});

  @override
  State<WellnessTestScreen> createState() => _WellnessTestScreenState();
}

class _WellnessTestScreenState extends State<WellnessTestScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Answers
  String _sleepQuality = 'Normal';
  double _sleepHours = 7;
  String _muscleSoreness = 'None';
  String _stressLevel = 'Low';
  String _energyLevel = 'Normal';
  String _mood = 'Normal';
  String _motivation = 'Normal';
  double _generalPain = 0;

  void _nextPage() {
    if (_currentPage < 7) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      widget.onComplete({
        'sleepQuality': _sleepQuality,
        'sleepHours': _sleepHours.round(),
        'muscleSoreness': _muscleSoreness,
        'stressLevel': _stressLevel,
        'energyLevel': _energyLevel,
        'mood': _mood,
        'motivation': _motivation,
        'generalPain': _generalPain.round(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Decorative Elements
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        Column(
          children: [
            // Integrated Progress Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: Colors.cyanAccent,
                  minHeight: 4,
                ),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildChoicePage(
                    question: "How was your sleep last night?",
                    icon: Icons.nightlight_round,
                    options: ['Very Good', 'Good', 'Normal', 'Poor', 'Very Poor'],
                    value: _sleepQuality,
                    onChanged: (v) => setState(() => _sleepQuality = v),
                  ),
                  _buildSliderPage(
                    question: "How many hours did you sleep?",
                    icon: Icons.access_time,
                    value: _sleepHours,
                    min: 2, max: 12, divisions: 20,
                    unit: "HRS",
                    onChanged: (v) => setState(() => _sleepHours = v),
                  ),
                  _buildChoicePage(
                    question: "How is your muscle soreness?",
                    icon: Icons.fitness_center,
                    options: ['None', 'Light', 'Moderate', 'Heavy'],
                    value: _muscleSoreness,
                    onChanged: (v) => setState(() => _muscleSoreness = v),
                  ),
                  _buildChoicePage(
                    question: "What is your current stress level?",
                    icon: Icons.psychology_outlined,
                    options: ['Low', 'Moderate', 'High'],
                    value: _stressLevel,
                    onChanged: (v) => setState(() => _stressLevel = v),
                  ),
                  _buildChoicePage(
                    question: "How is your energy level right now?",
                    icon: Icons.bolt,
                    options: ['High', 'Normal', 'Low'],
                    value: _energyLevel,
                    onChanged: (v) => setState(() => _energyLevel = v),
                  ),
                  _buildChoicePage(
                    question: "How is your mood today?",
                    icon: Icons.emoji_emotions_outlined,
                    options: ['Excellent', 'Good', 'Normal', 'Bad'],
                    value: _mood,
                    onChanged: (v) => setState(() => _mood = v),
                  ),
                  _buildChoicePage(
                    question: "What is your training motivation?",
                    icon: Icons.local_fire_department,
                    options: ['High', 'Normal', 'Low'],
                    value: _motivation,
                    onChanged: (v) => setState(() => _motivation = v),
                  ),
                  _buildSliderPage(
                    question: "General body pain? (FIFA scale 0-10)",
                    icon: Icons.healing_outlined,
                    value: _generalPain,
                    min: 0, max: 10, divisions: 10,
                    unit: "PAIN",
                    onChanged: (v) => setState(() => _generalPain = v),
                  ),
                ],
              ),
            ),

            // Next / Done button with Glass Design
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Center(
                    child: Text(
                      _currentPage < 7 ? 'CONTINUE →' : 'COMPLETE ASSESSMENT ✓',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoicePage({
    required String question,
    required IconData icon,
    required List<String> options,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass Card for Question
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.cyanAccent, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Selection List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: options.map((opt) {
                  final isSelected = value == opt;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onChanged(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.cyanAccent.withOpacity(0.1) 
                              : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.cyanAccent : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                color: isSelected ? Colors.cyanAccent : Colors.white70,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected) 
                              const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderPage({
    required String question,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required void Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.cyanAccent, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "${value.round()}",
                style: TextStyle(
                  color: Colors.cyanAccent.withOpacity(0.05),
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Column(
                children: [
                  Text(
                    "${value.round()}",
                    style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white10,
              trackHeight: 6,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayColor: Colors.cyanAccent.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
