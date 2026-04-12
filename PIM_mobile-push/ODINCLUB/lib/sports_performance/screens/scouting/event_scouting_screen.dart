import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/event_player.dart';
import '../../providers/events_provider.dart';
import '../../services/events_service.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';

/// Represents a player's evaluation entry with AI prediction result.
class _PlayerEvaluation {
  final EventPlayer eventPlayer;
  final AiAnalysisResult? aiAnalysis;
  String decision; // 'pending', 'recruited', 'rejected'

  _PlayerEvaluation({
    required this.eventPlayer,
    this.aiAnalysis,
    this.decision = 'pending',
  });

  double get aiConfidence => aiAnalysis?.confidence ?? 0;
  bool get isRecommended => aiAnalysis?.recruited ?? false;
  String get aiLabel {
    if (aiAnalysis == null) return '—';
    return aiAnalysis!.recruited ? 'RECRUTER' : 'PASSER';
  }
}

/// Integrated AI Scouting screen shown after event completion.
/// Shows all players with their test results + AI prediction.
/// Coach can accept or reject each player.
class EventScoutingScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventScoutingScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventScoutingScreen> createState() =>
      _EventScoutingScreenState();
}

class _EventScoutingScreenState extends ConsumerState<EventScoutingScreen> {
  List<_PlayerEvaluation> _evaluations = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  int _processedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final eventsService = ref.read(eventsServiceProvider);

      // 1. Trigger backend AI analysis for all completed players
      try {
        await eventsService.analyzeEvent(widget.eventId);
      } catch (_) {
        // Analysis may already be done or event has no completed players yet
      }

      // 2. Fetch all EventPlayers for this event
      final eventPlayers = await eventsService.getEventPlayers(widget.eventId);

      // 3. Only show players with AI analysis or completed status
      final relevantPlayers = eventPlayers
          .where((ep) =>
              ep.isCompleted || ep.hasAiAnalysis)
          .toList();

      if (relevantPlayers.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Aucun joueur complété disponible. Assurez-vous que les tests ont été saisis.';
        });
        return;
      }

      _totalCount = relevantPlayers.length;

      // 4. Build evaluations from stored AI analysis
      final evaluations = relevantPlayers.map((ep) {
        // Pre-fill decision from recruitmentDecision if already set
        String decision = 'pending';
        if (ep.recruitmentDecision == true) decision = 'recruited';
        if (ep.recruitmentDecision == false && ep.hasAiAnalysis) {
          decision = 'rejected';
        }
        return _PlayerEvaluation(
          eventPlayer: ep,
          aiAnalysis: ep.aiAnalysis,
          decision: decision,
        );
      }).toList();

      setState(() {
        _evaluations = evaluations;
        _processedCount = evaluations.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement: $e';
      });
    }
  }

  int get _recruitedCount =>
      _evaluations.where((e) => e.decision == 'recruited').length;
  int get _rejectedCount =>
      _evaluations.where((e) => e.decision == 'rejected').length;
  int get _pendingCount =>
      _evaluations.where((e) => e.decision == 'pending').length;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: SPColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ÉVALUATION IA',
          style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _evaluations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: SPColors.success),
              tooltip: 'Finaliser les décisions',
              onPressed: _pendingCount > 0 ? null : () => _showSummary(),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(eventAsync),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  color: SPColors.primaryBlue,
                  strokeWidth: 3,
                ),
                Icon(Icons.psychology,
                    size: 32, color: SPColors.primaryBlue.withOpacity(0.7)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse IA en cours...',
            style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '$_processedCount / $_totalCount joueurs analysés',
            style:
                SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _totalCount > 0 ? _processedCount / _totalCount : 0,
                backgroundColor: SPColors.backgroundSecondary,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(SPColors.primaryBlue),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncValue<Event> eventAsync) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: SPColors.warning),
              const SizedBox(height: 16),
              Text(_error!,
                  style: SPTypography.bodyMedium
                      .copyWith(color: SPColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEvaluations,
                icon: const Icon(Icons.refresh),
                label: const Text('RÉESSAYER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SPColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort: AI recommended first, then by score
    final sorted = List<_PlayerEvaluation>.from(_evaluations)
      ..sort((a, b) {
        // Pending first, then recruited, then rejected
        final orderMap = {'pending': 0, 'recruited': 1, 'rejected': 2};
        final orderDiff =
            (orderMap[a.decision] ?? 0) - (orderMap[b.decision] ?? 0);
        if (orderDiff != 0) return orderDiff;
        // Then by AI confidence descending
        return b.aiConfidence.compareTo(a.aiConfidence);
      });

    return Column(
      children: [
        _buildStatsHeader(eventAsync),
        _buildDecisionProgress(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: sorted.length,
            itemBuilder: (context, index) =>
                _buildPlayerEvaluationCard(sorted[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(AsyncValue<Event> eventAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SPColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology,
                        size: 16, color: SPColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      'ANALYSE IA',
                      style: SPTypography.overline.copyWith(
                        color: SPColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              eventAsync.when(
                data: (event) => Text(
                  event.title,
                  style: SPTypography.caption
                      .copyWith(color: SPColors.textTertiary),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                '${_evaluations.length}',
                'Joueurs',
                SPColors.primaryBlue,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                '${_evaluations.where((e) => e.isRecommended).length}',
                'Recommandés',
                SPColors.success,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                '${_evaluations.where((e) => !e.isRecommended && e.aiAnalysis != null).length}',
                'À passer',
                SPColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: SPTypography.h3
                    .copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: SPTypography.overline
                    .copyWith(color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionProgress() {
    final total = _evaluations.length;
    if (total == 0) return const SizedBox.shrink();

    final decided = _recruitedCount + _rejectedCount;
    final progress = decided / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DÉCISIONS',
                style: SPTypography.overline
                    .copyWith(color: SPColors.textTertiary),
              ),
              Row(
                children: [
                  _buildDecisionDot(SPColors.success, '$_recruitedCount'),
                  const SizedBox(width: 12),
                  _buildDecisionDot(SPColors.error, '$_rejectedCount'),
                  const SizedBox(width: 12),
                  _buildDecisionDot(SPColors.textTertiary, '$_pendingCount'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: SPColors.backgroundTertiary,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(SPColors.primaryBlue),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionDot(Color color, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(count,
            style: SPTypography.caption.copyWith(
                color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlayerEvaluationCard(_PlayerEvaluation eval) {
    final isRecruited = eval.decision == 'recruited';
    final isRejected = eval.decision == 'rejected';
    final isPending = eval.decision == 'pending';

    Color cardBorder = SPColors.borderPrimary;
    if (isRecruited) cardBorder = SPColors.success.withOpacity(0.5);
    if (isRejected) cardBorder = SPColors.error.withOpacity(0.3);

    final confidence = (eval.aiConfidence * 100).toInt();
    final confidenceColor = confidence >= 70
        ? SPColors.success
        : confidence >= 40
            ? SPColors.warning
            : SPColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRejected
            ? SPColors.backgroundSecondary.withOpacity(0.5)
            : SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: isRecruited ? 1.5 : 1),
      ),
      child: Column(
        children: [
          // Player header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Position index
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: eval.isRecommended
                        ? SPColors.primaryBlue.withOpacity(0.15)
                        : SPColors.backgroundTertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      eval.isRecommended ? Icons.thumb_up_alt : Icons.person_outline,
                      size: 16,
                      color: eval.isRecommended ? SPColors.primaryBlue : SPColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: SPColors.backgroundTertiary,
                  backgroundImage: eval.eventPlayer.player.photo != null
                      ? NetworkImage(eval.eventPlayer.player.photo!)
                      : null,
                  child: eval.eventPlayer.player.photo == null
                      ? Text(
                          eval.eventPlayer.player.firstName.isNotEmpty
                              ? eval.eventPlayer.player.firstName[0]
                              : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name & Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eval.eventPlayer.player.fullName,
                        style: SPTypography.bodyLarge.copyWith(
                          color: isRejected
                              ? SPColors.textTertiary
                              : SPColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: isRejected ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eval.eventPlayer.player.position.toUpperCase(),
                        style: SPTypography.overline.copyWith(
                          color: SPColors.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Potential Score
                if (eval.aiAnalysis?.potentialScore != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        eval.aiAnalysis!.potentialScore!.toStringAsFixed(0),
                        style: SPTypography.h4.copyWith(
                          color: SPColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'POTENTIEL',
                        style: SPTypography.overline.copyWith(
                            color: SPColors.textTertiary, fontSize: 8),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // AI Prediction bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SPColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // AI Recommendation
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: eval.isRecommended
                        ? SPColors.success.withOpacity(0.15)
                        : SPColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        eval.isRecommended
                            ? Icons.thumb_up_alt
                            : Icons.thumb_down_alt,
                        size: 14,
                        color: eval.isRecommended
                            ? SPColors.success
                            : SPColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        eval.aiLabel,
                        style: SPTypography.overline.copyWith(
                          color: eval.isRecommended
                              ? SPColors.success
                              : SPColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Confidence bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CONFIANCE IA',
                            style: SPTypography.overline.copyWith(
                              color: SPColors.textTertiary,
                              fontSize: 8,
                            ),
                          ),
                          Text(
                            '$confidence%',
                            style: SPTypography.caption.copyWith(
                              color: confidenceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: eval.aiConfidence,
                          backgroundColor: SPColors.backgroundTertiary,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(confidenceColor),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SHAP insights (if aiAnalysis available)
          if (eval.aiAnalysis?.shap != null && eval.aiAnalysis!.shap!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: eval.aiAnalysis!.shap!.entries.take(4).map((entry) {
                  final val = entry.value;
                  final isPositive = val is num ? val > 0 : false;
                  final color = isPositive ? SPColors.success : SPColors.warning;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${entry.key}',
                      style: SPTypography.overline.copyWith(color: color, fontSize: 9),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Cluster
          if (eval.aiAnalysis?.cluster != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 12, color: SPColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Profil: ${eval.aiAnalysis!.cluster}',
                    style: SPTypography.overline.copyWith(color: SPColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],

          // Decision buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: isPending
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setDecision(eval, 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('PASSER'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SPColors.error,
                            side: const BorderSide(color: SPColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _setDecision(eval, 'recruited'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('RECRUTER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SPColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () => _setDecision(eval, 'pending'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isRecruited
                            ? SPColors.success.withOpacity(0.1)
                            : SPColors.backgroundTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRecruited
                              ? SPColors.success.withOpacity(0.3)
                              : SPColors.borderPrimary,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRecruited
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: isRecruited
                                ? SPColors.success
                                : SPColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRecruited ? 'RECRUTÉ' : 'PASSÉ',
                            style: SPTypography.overline.copyWith(
                              color: isRecruited
                                  ? SPColors.success
                                  : SPColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'CHANGER',
                            style: SPTypography.overline.copyWith(
                              color: SPColors.primaryBlue,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.undo,
                              size: 12, color: SPColors.primaryBlue),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _setDecision(_PlayerEvaluation eval, String decision) {
    setState(() {
      eval.decision = decision;
    });
  }

  void _showSummary() {
    final recruited = _evaluations.where((e) => e.decision == 'recruited').toList();
    final rejected = _evaluations.where((e) => e.decision == 'rejected').toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SPColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check, color: SPColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Résumé des Décisions',
                style: SPTypography.h4.copyWith(color: SPColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              Icons.check_circle,
              SPColors.success,
              '${recruited.length} joueur(s) recruté(s)',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.cancel,
              SPColors.textTertiary,
              '${rejected.length} joueur(s) passé(s)',
            ),
            if (recruited.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: SPColors.borderPrimary),
              const SizedBox(height: 12),
              Text('RECRUTÉS',
                  style: SPTypography.overline
                      .copyWith(color: SPColors.success)),
              const SizedBox(height: 8),
              ...recruited.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: SPColors.backgroundTertiary,
                          child: Text(
                            e.eventPlayer.player.firstName.isNotEmpty
                                ? e.eventPlayer.player.firstName[0]
                                : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.eventPlayer.player.fullName,
                            style: SPTypography.bodySmall
                                .copyWith(color: SPColors.textPrimary),
                          ),
                        ),
                        Text(
                          '${(e.aiConfidence * 100).toInt()}%',
                          style: SPTypography.caption.copyWith(
                            color: SPColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('MODIFIER',
                style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _finalize();
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('CONFIRMER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SPColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text,
            style: SPTypography.bodyMedium.copyWith(color: SPColors.textPrimary)),
      ],
    );
  }

  Future<void> _finalize() async {
    final eventsService = ref.read(eventsServiceProvider);

    // Persist each decision to the backend
    for (final eval in _evaluations) {
      if (eval.decision == 'pending') continue;
      try {
        await eventsService.setRecruitmentDecision(
          widget.eventId,
          eval.eventPlayer.player.id!,
          decision: eval.decision == 'recruited',
        );
      } catch (_) {
        // Non-blocking — continue saving others
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '$_recruitedCount joueur(s) recruté(s), $_rejectedCount passé(s)',
            ),
          ],
        ),
        backgroundColor: SPColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // Go back to the event list
    Navigator.of(context)
      ..pop()
      ..pop();
  }
}
