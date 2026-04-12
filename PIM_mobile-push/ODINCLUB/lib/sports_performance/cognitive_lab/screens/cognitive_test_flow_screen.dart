import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../user_management/models/user_management_models.dart';
import '../providers/cognitive_lab_provider.dart';
import 'tests/reaction_test_screen.dart';
import 'tests/focus_test_screen.dart';
import 'tests/memory_test_screen.dart';
import 'tests/decision_test_screen.dart';
import 'tests/wellness_test_screen.dart';

class CognitiveTestFlowScreen extends StatefulWidget {
  final SessionModel session;
  final String? targetPlayerId;
  const CognitiveTestFlowScreen({super.key, required this.session, this.targetPlayerId});

  @override
  State<CognitiveTestFlowScreen> createState() => _CognitiveTestFlowScreenState();
}

class _CognitiveTestFlowScreenState extends State<CognitiveTestFlowScreen> {
  int _currentStep = 0;
  // Total steps: 0=Wellness, 1=Reaction, 2=Focus, 3=Memory, 4=Decision
  static const int _totalSteps = 5;

  Map<String, dynamic> _sessionData = {};

  static const List<String> _stepLabels = [
    '🧘 Wellness Check',
    '⚡ Reaction',
    '🎯 Focus',
    '🧠 Memory',
    '🏆 Decision Making',
  ];

  void _onWellnessComplete(Map<String, dynamic> results) {
    _sessionData['wellness'] = results;
    setState(() => _currentStep++);
  }

  void _onReactionComplete(Map<String, int> results) {
    _sessionData['reaction'] = results;
    setState(() => _currentStep++);
  }

  void _onFocusComplete(Map<String, int> results) {
    _sessionData['focus'] = results;
    setState(() => _currentStep++);
  }

  void _onMemoryComplete(Map<String, int> results) {
    _sessionData['memory'] = results;
    setState(() => _currentStep++);
  }

  void _onDecisionComplete(Map<String, dynamic> results) async {
    _sessionData['decision'] = results;
    _sessionData['playerId'] = widget.targetPlayerId ?? widget.session.userId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    try {
      await context.read<CognitiveLabProvider>().submitSession(_sessionData);

      if (mounted) {
        Navigator.pop(context); // close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ÉVALUATION TERMINÉE AVEC SUCCÈS 🏆"),
            backgroundColor: Colors.cyanAccent,
          ),
        );
        
        Navigator.pop(context, true); // return to dashboard with 'true' to signal refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ERREUR LORS DE L'ENREGISTREMENT: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentTest;

    switch (_currentStep) {
      case 0:
        currentTest = WellnessTestScreen(onComplete: _onWellnessComplete);
        break;
      case 1:
        currentTest = ReactionTestScreen(onComplete: _onReactionComplete);
        break;
      case 2:
        currentTest = FocusTestScreen(onComplete: _onFocusComplete);
        break;
      case 3:
        currentTest = MemoryTestScreen(onComplete: _onMemoryComplete);
        break;
      case 4:
        currentTest = DecisionTestScreen(onComplete: _onDecisionComplete);
        break;
      default:
        currentTest = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test ${_currentStep + 1}/$_totalSteps',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text(
              _stepLabels[_currentStep < _totalSteps ? _currentStep : _totalSteps - 1],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: currentTest,
    );
  }
}
