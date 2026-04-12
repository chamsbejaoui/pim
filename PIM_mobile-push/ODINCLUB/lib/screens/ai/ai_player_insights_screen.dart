import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';
import '../../models/ai_player.dart';
import '../../services/ai_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../sports_performance/screens/exercises/generator_form.dart';

/// Deep AI insights: similar players, potential score, development plan.
class AiPlayerInsightsScreen extends StatefulWidget {
  final AiPlayer player;
  const AiPlayerInsightsScreen({super.key, required this.player});

  @override
  State<AiPlayerInsightsScreen> createState() =>
      _AiPlayerInsightsScreenState();
}

class _AiPlayerInsightsScreenState extends State<AiPlayerInsightsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _similarData;
  Map<String, dynamic>? _potentialData;
  Map<String, dynamic>? _planData;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    // Load each section independently — one failure doesn't block others
    final results = await Future.wait([
      AiApiService.findSimilarPlayers(widget.player).then<Map<String, dynamic>?>(
        (v) => v,
        onError: (e) => {'error': 'Unavailable'},
      ),
      AiApiService.getPlayerPotential(widget.player).then<Map<String, dynamic>?>(
        (v) => v,
        onError: (e) => {'error': 'Unavailable'},
      ),
      AiApiService.getDevelopmentPlan(widget.player).then<Map<String, dynamic>?>(
        (v) => v,
        onError: (e) => {'error': 'Unavailable'},
      ),
    ]);

    if (mounted) {
      setState(() {
        _similarData = results[0];
        _potentialData = results[1];
        _planData = results[2];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AiColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.player.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AiColors.primary.withOpacity(0.3),
                      AiColors.backgroundDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AiColors.primary.withOpacity(0.3),
                        child: Text(
                          widget.player.name.isNotEmpty
                              ? widget.player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.player.club ?? 'Unknown Club',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(
                      color: AiColors.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPotentialSection(),
                  const SizedBox(height: 24),
                  _buildSimilarSection(),
                  const SizedBox(height: 24),
                  _buildDevelopmentPlanSection(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AiColors.backgroundDark,
          border: const Border(
              top: BorderSide(color: AiColors.borderDark)),
        ),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                context
                    .read<CampaignProvider>()
                    .skipPlayer(widget.player);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Player Skipped')));
              },
              icon: const Icon(Icons.close),
              label: const Text('Skip'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AiColors.borderDark),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context
                    .read<CampaignProvider>()
                    .recruitPlayer(widget.player);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('${widget.player.name} Recruited!'),
                  backgroundColor: AiColors.primary,
                ));
              },
              icon: const Icon(Icons.check),
              label: const Text('Recruit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AiColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══ POTENTIAL SCORE ═══
  Widget _buildPotentialSection() {
    if (_potentialData == null ||
        _potentialData!.containsKey('error')) {
      return _errorCard('Potential Score',
          _potentialData?['error'] ?? 'Unavailable');
    }

    final score =
        (_potentialData!['potential_score'] as num).toDouble();
    final ageFactor =
      (_potentialData!['age_factor'] ??
          _potentialData!['dateOfBirth_factor'])
        as String? ??
      '';
    final currentCluster =
        _potentialData!['current_cluster'] as String? ?? 'Unknown';
    final eliteGap = _potentialData!['elite_gap']
            as Map<String, dynamic>? ??
        {};

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.trending_up, 'Potential Score', AiColors.success),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _CircularGaugePainter(score: score),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${score.round()}',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(score))),
                      Text('/100',
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(spacing: 8, children: [
              _badge(currentCluster, AiColors.primary),
              _badge(ageFactor, AiColors.info),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('Gap to Elite',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 8),
          ...eliteGap.entries.map((e) => _buildGapBar(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildGapBar(String feature, dynamic gapData) {
    if (gapData is! Map) return const SizedBox.shrink();
    final current =
        (gapData['current'] as num?)?.toDouble() ?? 0;
    final target =
        (gapData['elite_target'] as num?)?.toDouble() ?? 0;
    final gap = (gapData['gap'] as num?)?.toDouble() ?? 0;
    final direction =
        gapData['direction'] as String? ?? 'increase';

    final isGood = gap <= 0;
    final barColor = isGood ? AiColors.success : AiColors.warning;
    final maxVal = max(current, target) * 1.1;
    final ratio =
        maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                feature
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                style: const TextStyle(
                    color: AiColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            Text(
                '${current.toStringAsFixed(1)} → ${target.toStringAsFixed(1)} ($direction)',
                style: TextStyle(
                    color: isGood
                        ? AiColors.success
                        : AiColors.textSecondary,
                    fontSize: 10)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: barColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 4,
          ),
        ),
      ]),
    );
  }

  // ═══ SIMILAR PLAYERS ═══
  Widget _buildSimilarSection() {
    if (_similarData == null ||
        _similarData!.containsKey('error')) {
      return _errorCard('Similar Players',
          _similarData?['error'] ?? 'Unavailable');
    }

    final similar =
        (_similarData!['similar_players'] as List?) ?? [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.people_outline, 'Similar Players', AiColors.info),
          const SizedBox(height: 12),
          if (similar.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No similar players found',
                    style: TextStyle(
                        color: AiColors.textSecondary)),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                itemBuilder: (context, index) {
                  final p = similar[index];
                  return _similarPlayerCard(p, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _similarPlayerCard(Map<String, dynamic> p, int index) {
    final name = p['name'] as String? ?? 'Unknown';
    final similarity =
        (p['similarity_pct'] as num?)?.toDouble() ?? 0;
    final cluster = p['cluster_label'] as String? ?? '';
    final colors = [
      AiColors.primary,
      AiColors.success,
      AiColors.info,
      AiColors.warning,
      AiColors.primaryLight
    ];
    final color = colors[index % colors.length];

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text('${similarity.round()}% match',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(cluster,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9)),
        ],
      ),
    );
  }

  // ═══ DEVELOPMENT PLAN ═══
  Widget _buildDevelopmentPlanSection() {
    if (_planData == null || _planData!.containsKey('error')) {
      return _errorCard('Development Plan',
          _planData?['error'] ?? 'Unavailable');
    }

    final improvements =
        (_planData!['improvements'] as List?) ?? [];
    final strengths = (_planData!['strengths'] as List?) ?? [];
    final summary = _planData!['summary'] as String? ?? '';
    final confidence =
        (_planData!['recruitment_confidence'] as num?)?.toDouble() ??
            0;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.fitness_center, 'Development Plan',
              AiColors.warning),
          const SizedBox(height: 4),
          Text(summary,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11)),
          const SizedBox(height: 16),
          if (strengths.isNotEmpty) ...[
            const Text('💪 Strengths',
                style: TextStyle(
                    color: AiColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            ...strengths.map((s) => _strengthItem(s)),
            const SizedBox(height: 16),
          ],
          if (improvements.isNotEmpty) ...[
            const Text('🎯 Areas to Improve',
                style: TextStyle(
                    color: AiColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            ...improvements.map((item) => _improvementItem(item)),
          ],
          if (improvements.isEmpty && strengths.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Recruitment confidence: ${confidence.round()}%\nNo specific improvements identified.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AiColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _strengthItem(dynamic s) {
    if (s is! Map) return const SizedBox.shrink();
    final feature =
        (s['feature'] as String? ?? '').replaceAll('_', ' ');
    final note = s['note'] as String? ?? '';
    final value =
        (s['current_value'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const Icon(Icons.check_circle,
            color: AiColors.success, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5)),
              Text(note,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10)),
            ],
          ),
        ),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(
                color: AiColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ]),
    );
  }

  Widget _improvementItem(dynamic item) {
    if (item is! Map) return const SizedBox.shrink();
    final feature =
        (item['feature'] as String? ?? '').replaceAll('_', ' ');
    final current =
        (item['current_value'] as num?)?.toDouble() ?? 0;
    final target = item['target_value'] as num?;
    final priority = item['priority'] as String? ?? 'medium';
    final recommendation =
        item['recommendation'] as String? ?? '';

    final isHigh = priority == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isHigh ? AiColors.error : AiColors.warning)
            .withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (isHigh ? AiColors.error : AiColors.warning)
                .withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isHigh ? AiColors.error : AiColors.warning)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(priority.toUpperCase(),
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isHigh
                          ? AiColors.error
                          : AiColors.warning,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(recommendation,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10)),
                ],
              ),
            ),
            if (target != null)
              Text(
                  '${current.toStringAsFixed(0)} → ${target.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AiColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeneratorForm(
                      initialPlayerId: widget.player.id,
                      initialObjective: feature,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isHigh ? AiColors.error.withOpacity(0.2) : AiColors.warning.withOpacity(0.2),
                foregroundColor: isHigh ? AiColors.error : AiColors.warning,
                elevation: 0,
                side: BorderSide(color: (isHigh ? AiColors.error : AiColors.warning).withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CRÉER EXERCICE CORRECTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ SHARED WIDGETS ═══
  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AiColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiColors.glassBorder),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _errorCard(String title, String message) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.error_outline, title, AiColors.error),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  color: AiColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AiColors.success;
    if (score >= 60) return AiColors.info;
    if (score >= 40) return AiColors.warning;
    return AiColors.error;
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double score;
  _CircularGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75, pi * 1.5, false, bgPaint);

    final ratio = (score / 100).clamp(0.0, 1.0);
    Color color;
    if (score >= 80) {
      color = AiColors.success;
    } else if (score >= 60) {
      color = AiColors.info;
    } else if (score >= 40) {
      color = AiColors.warning;
    } else {
      color = AiColors.error;
    }

    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75, pi * 1.5 * ratio, false, scorePaint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75, pi * 1.5 * ratio, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
