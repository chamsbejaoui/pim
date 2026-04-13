import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/ai_colors.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/ai/ai_glass_chip.dart';
import '../../widgets/ai/ai_bottom_action_bar.dart';
import 'ai_candidates_tab.dart';
import 'ai_archive_tab.dart';
import 'ai_insights_tab.dart';
import 'ai_create_player_screen.dart';
import 'ai_report_import_screen.dart';
import 'ai_compare_players_screen.dart';

/// Main AI scouting campaign screen with 3 tabs:
/// Candidates, Archives, AI Insights.
class AiCampaignScreen extends StatefulWidget {
  const AiCampaignScreen({super.key});

  @override
  State<AiCampaignScreen> createState() => _AiCampaignScreenState();
}

class _AiCampaignScreenState extends State<AiCampaignScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      context.read<CampaignProvider>().setActiveTab(_tabController.index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AiCreatePlayerScreen()));
        },
        backgroundColor: AiColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  expandedHeight: 240,
                  backgroundColor:
                      AiColors.backgroundDark.withOpacity(0.8),
                  surfaceTintColor: Colors.transparent,
                  leading: _buildCircleButton(
                      Icons.arrow_back_ios_new,
                      () => Navigator.maybePop(context)),
                  actions: [
                    _buildCircleButton(Icons.description, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AiReportImportScreen()));
                    }),
                    const SizedBox(width: 4),
                    Consumer<CampaignProvider>(
                      builder: (context, provider, _) {
                        return _buildCircleButton(
                            Icons.stop_circle_outlined,
                            () => _showEndSessionDialog(provider));
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildCircleButton(Icons.more_horiz, () {}),
                    const SizedBox(width: 8),
                  ],
                  title: innerBoxIsScrolled
                      ? const Text('AI Scouting Campaign',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold))
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeaderContent(),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: _buildTabBar(),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: const [
                AiCandidatesTab(),
                AiArchiveTab(),
                AiInsightsTab(),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<CampaignProvider>(
              builder: (context, provider, _) {
                return AiBottomActionBar(
                  selectedCount: provider.selectedCount,
                  onClearAll: provider.clearSelection,
                  onSendConvocation: () =>
                      _showConvocationDialog(provider),
                  onCompare: provider.selectedCount == 2
                      ? () {
                          final players = provider.selectedPlayers;
                          if (players.length == 2) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AiComparePlayersScreen(
                                            playerA: players[0],
                                            playerB: players[1])));
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AiColors.cardDark,
            border: Border.all(color: AiColors.borderDark),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ACTIVE SCOUTING',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AiColors.primary)),
            const SizedBox(height: 4),
            const Text('AI Scouting Campaign',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    AiGlassChip(
                        icon: Icons.group,
                        iconColor: AiColors.primary,
                        label: 'Scouts Active'),
                    SizedBox(width: 8),
                    AiGlassChip(
                        icon: Icons.person_search,
                        iconColor: AiColors.success,
                        label: 'AI Powered'),
                    SizedBox(width: 8),
                    AiGlassChip(
                        icon: Icons.psychology,
                        iconColor: AiColors.warning,
                        label: 'ML Model'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AiColors.borderDark, width: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorWeight: 2,
        indicatorColor: AiColors.primary,
        labelColor: Colors.white,
        unselectedLabelColor: AiColors.textTertiary,
        tabs: const [
          Tab(text: 'Candidates'),
          Tab(text: 'Archives'),
          Tab(text: 'AI Insights'),
        ],
      ),
    );
  }

  void _showConvocationDialog(CampaignProvider provider) {
    final players = provider.selectedPlayers;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AiColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.send, color: AiColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Send Convocation',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Send convocation to ${players.length} player${players.length != 1 ? 's' : ''}:',
                style: const TextStyle(
                    color: AiColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            ...players.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 16,
                        backgroundColor: AiColors.cardDark,
                        child: Text(p.name[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                  ]),
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.sendConvocation();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    '✅ Convocation sent to ${players.length} player${players.length != 1 ? 's' : ''}!'),
                backgroundColor: AiColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog(CampaignProvider provider) {
    if (provider.players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No players in the session to end'),
        backgroundColor: AiColors.warning,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AiColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.stop_circle_outlined,
              color: AiColors.warning, size: 22),
          SizedBox(width: 8),
          Text('End Session',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this scouting session?',
                style: TextStyle(
                    color: AiColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            _buildSessionStatRow(Icons.check_circle, AiColors.success,
                '${provider.recruitedCount} recruited', 'Will remain active'),
            const SizedBox(height: 8),
            _buildSessionStatRow(
                Icons.archive_outlined,
                AiColors.warning,
                '${provider.toArchiveCount} not recruited',
                'Will be archived'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.endSession();
              if (context.mounted) {
                if (provider.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(provider.error ?? 'Error ending session'),
                    backgroundColor: AiColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '✅ Session ended — ${provider.archivedPlayers.length} players archived'),
                    backgroundColor: AiColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                  _tabController.animateTo(1);
                }
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AiColors.warning),
            child: const Text('End Session',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatRow(
      IconData icon, Color color, String title, String subtitle) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(subtitle,
            style: const TextStyle(
                color: AiColors.textMuted, fontSize: 11)),
      ]),
    ]);
  }
}
