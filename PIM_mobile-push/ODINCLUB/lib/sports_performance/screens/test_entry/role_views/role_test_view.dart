import 'package:flutter/material.dart';
import '../../../models/test_type.dart';
import '../../../models/test_result.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';
import '../widgets/odin_test_card.dart';

class RoleTestConfig {
  final String name;
  final String unit;
  final double min;
  final double max;
  final bool lowerIsBetter;

  RoleTestConfig({
    required this.name,
    required this.unit,
    this.min = 0,
    this.max = 100,
    this.lowerIsBetter = false,
  });
}

class RoleTestView extends StatelessWidget {
  final List<RoleTestConfig> configs;
  final List<TestType> availableTests;
  final Map<String, double> currentResults;
  final Function(String, double) onResultChanged;
  final bool isEventSelectionEnabled;
  final List<RoleTestConfig>? eventSpecificConfigs;

  const RoleTestView({
    super.key,
    required this.configs,
    required this.availableTests,
    required this.currentResults,
    required this.onResultChanged,
    this.isEventSelectionEnabled = false,
    this.eventSpecificConfigs,
  });

  @override
  Widget build(BuildContext context) {
    final List<RoleTestConfig> eventTests = eventSpecificConfigs ?? [];
    final List<RoleTestConfig> otherTests = configs;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (eventTests.isNotEmpty) ...[
          _buildHeader('EVENT SPECIFIC TESTS', Icons.star),
          const SizedBox(height: 8),
          ...eventTests.map((c) => _buildTestCard(c)),
          const SizedBox(height: 24),
        ],
        if (otherTests.isNotEmpty) ...[
          _buildHeader('RECOMMENDED FOR POSITION', Icons.person_outline),
          const SizedBox(height: 8),
          ...otherTests.map((c) => _buildTestCard(c)),
        ],
      ],
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: SPColors.primaryBlue, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: SPTypography.overline.copyWith(
              color: SPColors.primaryBlue,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(RoleTestConfig config) {
    final matchingTest = availableTests.firstWhere(
      (t) => t.name.toLowerCase().contains(config.name.toLowerCase()),
      orElse: () => _createDummyTestType(config),
    );

    return OdinTestCard(
      testType: matchingTest,
      initialValue: currentResults[matchingTest.id],
      onChanged: (value) => onResultChanged(matchingTest.id, value),
      min: config.min,
      max: config.max,
      lowerIsBetter: config.lowerIsBetter,
    );
  }

  TestType _createDummyTestType(RoleTestConfig config) {
    return TestType(
      id: 'dummy_${config.name.replaceAll(' ', '_')}', // Dummy ID won't save unless backend handles it, but keeps UI working
      name: config.name,
      category: TestCategory.technical, // Default
      description: 'Auto-generated for UI',
      unit: config.unit,
      scoringMethod: config.lowerIsBetter 
          ? ScoringMethod.lowerBetter 
          : ScoringMethod.higherBetter,
      weight: 1.0,
      betterIsHigher: !config.lowerIsBetter,
      isActive: true,
      minThreshold: config.min,
      maxThreshold: config.max,
    );
  }
}
