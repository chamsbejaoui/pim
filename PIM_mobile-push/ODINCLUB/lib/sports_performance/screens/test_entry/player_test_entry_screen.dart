import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_player.dart';
import '../../models/event.dart';
import '../../models/test_type.dart';
import '../../models/test_result.dart';
import '../../providers/test_types_provider.dart';
import '../../providers/test_results_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import 'role_views/role_test_view.dart';
import '../../models/player.dart';

class PlayerTestEntryScreen extends ConsumerStatefulWidget {
  final EventPlayer eventPlayer;

  const PlayerTestEntryScreen({
    super.key,
    required this.eventPlayer,
  });

  @override
  ConsumerState<PlayerTestEntryScreen> createState() => _PlayerTestEntryScreenState();
}

class _PlayerTestEntryScreenState extends ConsumerState<PlayerTestEntryScreen> {
  final Map<String, double> _results = {};
  // Map to store existing result IDs: testTypeId -> resultId
  final Map<String, String> _existingResultIds = {};
  
  final List<RoleTestConfig> _attackerConfig = [
    RoleTestConfig(name: 'Finishing', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Shooting Power', unit: 'km/h', min: 50, max: 180),
    RoleTestConfig(name: 'Acceleration', unit: 's', min: 3.5, max: 10.0, lowerIsBetter: true),
    RoleTestConfig(name: 'Dribbling', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Off-ball Movement', unit: '%', min: 0, max: 100),
  ];

  final List<RoleTestConfig> _midfielderConfig = [
    RoleTestConfig(name: 'Passing Accuracy', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Vision', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Stamina (VMA)', unit: 'km/h', min: 10, max: 25),
    RoleTestConfig(name: 'Ball Control', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Decision Making', unit: '%', min: 0, max: 100),
  ];

  final List<RoleTestConfig> _defenderConfig = [
    RoleTestConfig(name: 'Tackling', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Defensive Positioning', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Strength', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Aerial Duel', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Awareness', unit: '%', min: 0, max: 100),
  ];

  final List<RoleTestConfig> _gkConfig = [
    RoleTestConfig(name: 'Reflexes', unit: 'ms', min: 100, max: 1000, lowerIsBetter: true),
    RoleTestConfig(name: 'Jump Reach', unit: 'cm', min: 200, max: 360),
    RoleTestConfig(name: 'Handling', unit: '%', min: 0, max: 100),
    RoleTestConfig(name: 'Reaction Time', unit: 'ms', min: 100, max: 1000, lowerIsBetter: true),
    RoleTestConfig(name: 'Distribution', unit: '%', min: 0, max: 100),
  ];

  @override
  Widget build(BuildContext context) {
    final activeTestTypesAsync = ref.watch(activeTestTypesProvider);
    final existingResultsAsync = ref.watch(testResultsProvider(widget.eventPlayer.id));
    final eventAsync = ref.watch(eventProvider(widget.eventPlayer.eventId));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          'RESULT ENTRY',
          style: SPTypography.button.copyWith(
            color: SPColors.textTertiary,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildPlayerHeader(),
          Expanded(
            child: eventAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading event: $e')),
              data: (event) => activeTestTypesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
                data: (testTypes) {
                  return existingResultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error loading results: $e')),
                    data: (existingResults) {
                      if (_results.isEmpty && existingResults.isNotEmpty) {
                        for (var result in existingResults) {
                          _results[result.testType.id] = result.rawValue;
                          _existingResultIds[result.testType.id] = result.id;
                        }
                      }

                      return _buildSmartRoleContent(event, testTypes, existingResults);
                    },
                  );
                },
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SPColors.primaryBlue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/placeholder_player.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                widget.eventPlayer.player.firstName.isNotEmpty && widget.eventPlayer.player.lastName.isNotEmpty 
                    ? widget.eventPlayer.player.firstName[0] + widget.eventPlayer.player.lastName[0]
                    : 'P',
                style: SPTypography.h4.copyWith(color: SPColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventPlayer.player.fullName,
                  style: SPTypography.h5.copyWith(color: SPColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.eventPlayer.player.position} • First Team',
                  style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SPColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '10',
              style: SPTypography.h5.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRoleContent(Event event, List<TestType> allTestTypes, List<TestResult> existingResults) {
    // 1. Identify tests specifically selected for this event
    final List<TestType> eventSpecificTests = allTestTypes.where((t) => event.testTypes.contains(t.id)).toList();

    // 2. Identify role-based recommendations
    final position = widget.eventPlayer.player.position.toLowerCase();
    List<RoleTestConfig> positionConfig;
    
    if (position.contains('at') || position.contains('fw') || position.contains('striker') || position.contains('attack')) {
      positionConfig = _attackerConfig;
    } else if (position.contains('mid') || position.contains('md')) {
      positionConfig = _midfielderConfig;
    } else if (position.contains('def') || position.contains('df') || position.contains('back')) {
      positionConfig = _defenderConfig;
    } else if (position.contains('gk') || position.contains('goal') || position.contains('gardien')) {
      positionConfig = _gkConfig;
    } else {
      positionConfig = _attackerConfig; 
    }

    // 3. Logic: Focus Mode (Specialized) vs Global Mode
    final List<RoleTestConfig> eventConfigs = [];
    final List<RoleTestConfig> positionConfigs = [];
    final Set<String> processedTestNames = {};

    // 1. Always identify event-specific tests
    for (var test in eventSpecificTests) {
      eventConfigs.add(RoleTestConfig(
        name: test.name,
        unit: test.unit,
        min: test.minThreshold ?? 0,
        max: test.maxThreshold ?? 100,
        lowerIsBetter: test.scoringMethod == ScoringMethod.lowerBetter,
      ));
      processedTestNames.add(test.name.toLowerCase());
    }

    // 2. Identify position recommendations ONLY IF NOT in Focus Mode
    if (!event.type.isSpecialized) {
      for (var config in positionConfig) {
        if (!processedTestNames.contains(config.name.toLowerCase())) {
          positionConfigs.add(config);
          processedTestNames.add(config.name.toLowerCase());
        }
      }
    }

    return RoleTestView(
      availableTests: allTestTypes,
      eventSpecificConfigs: eventConfigs,
      configs: positionConfigs,
      currentResults: _results,
      onResultChanged: (testId, value) {
        setState(() {
          _results[testId] = value;
        });
      },
      isEventSelectionEnabled: eventConfigs.isNotEmpty,
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        border: const Border(top: BorderSide(color: SPColors.borderPrimary)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: SPColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('SAVE & COMPLETE'),
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveResults() async {
    if (_results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No results to save')),
      );
      return;
    }

    final notifier = ref.read(testResultFormProvider.notifier);
    
    try {
      // Save all results (Update existing or Create new)
      for (final entry in _results.entries) {
        final testTypeId = entry.key;
        final value = entry.value;
        final existingId = _existingResultIds[testTypeId];

        TestResult? savedResult;
        if (existingId != null) {
          // Update existing
          savedResult = await notifier.updateTestResult(
            id: existingId,
            eventPlayerId: widget.eventPlayer.id,
            rawValue: value,
          );
        } else {
          // Create new
          savedResult = await notifier.createTestResult(
            eventPlayerId: widget.eventPlayer.id,
            testTypeId: testTypeId,
            rawValue: value,
          );
        }

        if (savedResult == null) {
          throw Exception('Failed to save result for test $testTypeId');
        }
      }
      
      // Update player status to completed
      final eventNotifier = ref.read(eventFormProvider.notifier);
      final updatedPlayer = await eventNotifier.updateEventPlayerStatus(
        widget.eventPlayer.eventId,
        widget.eventPlayer.player.id!,
        ParticipationStatus.completed,
      ); 

      if (updatedPlayer == null) {
        throw Exception('Failed to update player status');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }
}
