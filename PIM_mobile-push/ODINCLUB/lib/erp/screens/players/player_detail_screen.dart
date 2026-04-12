import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/erp_access.dart';
import '../../providers/players_provider.dart';
import '../../widgets/status_badge.dart';
import '../../../ui/shell/app_shell.dart';
import 'player_form_screen.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String? playerId;
  const PlayerDetailScreen({super.key, this.playerId});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final session = AppShellScope.of(context)?.session;
      final id = widget.playerId ?? session?.userId;
      
      if (id != null) {
        final provider = Provider.of<PlayersProvider>(context, listen: false);
        provider.fetchPlayer(id);
        provider.fetchHistory(id);
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayersProvider>(context);
    final player = provider.selectedPlayer;
    final df = DateFormat('dd/MM/yyyy');

    if (provider.error != null && player == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: OdinTheme.accentRed, size: 48),
              const SizedBox(height: 16),
              Text(provider.error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final session = AppShellScope.of(context)?.session;
                  final id = widget.playerId ?? session?.userId;
                  if (id != null) {
                    provider.fetchPlayer(id);
                    provider.fetchHistory(id);
                  }
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if ((provider.isLoading && player == null) || player == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: OdinTheme.primaryBlue),
        ),
      );
    }

    final session = AppShellScope.of(context)?.session;
    final isAdmin = erpIsAdminRole(session?.role);
    final isSelf = session?.userId == player.id;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: OdinTheme.primaryGradient,
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      player.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    player.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      StatusBadge(status: player.status),
                      Text(
                        '${player.position} • #${player.jerseyNumber ?? '-'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isAdmin || isSelf)
                    Align(
                      alignment: Alignment.centerRight,
                      child: isAdmin
                          ? PopupMenuButton<String>(
                              color: OdinTheme.surface,
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                              onSelected: (val) => _handleAction(val, player.id),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Modifier')),
                                const PopupMenuItem(
                                    value: 'status', child: Text('Changer statut')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer',
                                      style: TextStyle(color: OdinTheme.accentRed)),
                                ),
                              ],
                            )
                          : IconButton(
                              icon: const Icon(Icons.settings_rounded, color: Colors.white),
                              onPressed: () => _showPlayerSettingsDialog(player),
                            ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Tab bar ───────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: OdinTheme.primaryBlue,
                labelColor: OdinTheme.primaryBlue,
                unselectedLabelColor: OdinTheme.textTertiary,
                tabs: const [
                  Tab(text: 'PROFIL'),
                  Tab(text: 'HISTORIQUE'),
                ],
              ),
            ),
          ),

          // ─── Tab content ───────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfile(player, df),
                _buildHistory(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(dynamic player, DateFormat df) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ─── Performance AI & Stats ──────────
          if (player.aiScore != null || player.stats != null) ...[
            _buildSection('Performance & AI Score', [
              if (player.aiScore != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OdinTheme.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OdinTheme.primaryBlue.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${player.aiScore}',
                        style: const TextStyle(
                          color: OdinTheme.primaryBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Odin Match AI Score\nAnalyse basée sur les dernières performances',
                        style: TextStyle(color: OdinTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              if (player.aiScore != null && player.stats != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: OdinTheme.cardBorder),
                ),
              if (player.stats != null)
                ...((player.stats as Map<String, dynamic>).entries.map((e) {
                  return _infoRow(
                      e.key.replaceAll('_', ' ').toUpperCase(), '${e.value}');
                }).toList()),
            ]),
            const SizedBox(height: 16),
          ],

          // ─── Personal info card ──────────────
          _buildSection('Informations Personnelles', [
            _infoRow('Date de naissance',
                player.dateOfBirth != null ? df.format(player.dateOfBirth!) : '-'),
            _infoRow('Nationalité', player.nationality ?? '-'),
            _infoRow('Taille', player.height != null ? '${player.height} cm' : '-'),
            _infoRow('Poids', player.weight != null ? '${player.weight} kg' : '-'),
            _infoRow('Pied préféré', player.preferredFoot ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ─── Team / Category ─────────────────
          _buildSection('Affectation', [
            _infoRow('Équipe', player.teamName ?? 'Non assigné'),
            _infoRow('Catégorie', player.categoryName ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ─── Contract & Medical ──────────────
          _buildSection('Détails Contrat & Médical', [
            _infoRow('Début',
                player.contractStartDate != null ? df.format(player.contractStartDate!) : '-'),
            _infoRow('Fin',
                player.contractEndDate != null ? df.format(player.contractEndDate!) : '-'),
            if (player.salary != null)
              _infoRow('Salaire', '${player.salary} MAD'),
            if (player.medicalNotes != null)
              _infoRow('Dossier Médical', player.medicalNotes!),
            if (player.isProspect == true)
              _infoRow('Statut', 'Cible de recrutement (Prospect)'),
            if (player.returnDate != null)
              _infoRow('Date de Retour Prévue', df.format(player.returnDate!)),
          ]),
          
          const SizedBox(height: 16),
          
          // ─── Activity & System ──────────────
          _buildSection('Activité Système', [
            _infoRow('Date d\'ajout', player.createdAt != null ? df.format(player.createdAt!) : '-'),
            _infoRow('Créé par', player.createdBy ?? 'Système'),
            _infoRow('ID Joueur', player.id.toString()),
          ]),
        ],
      ),
    );
  }

  Widget _buildHistory(PlayersProvider provider) {
    final history = provider.history;
    if (history.isEmpty) {
      return const Center(
        child: Text('Aucun historique',
            style: TextStyle(color: OdinTheme.textTertiary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final typeColors = {
          'status_change': OdinTheme.accentOrange,
          'injury': OdinTheme.accentRed,
          'suspension': OdinTheme.accentRed,
          'team_change': OdinTheme.accentCyan,
          'profile_update': OdinTheme.primaryBlue,
        };
        final color = typeColors[h.eventType] ?? OdinTheme.textTertiary;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: OdinTheme.glassCard,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.eventType.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    if (h.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        h.description!,
                        style: const TextStyle(
                          color: OdinTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (h.previousValue != null || h.newValue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${h.previousValue ?? ''} → ${h.newValue ?? ''}',
                        style: const TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (h.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(h.createdAt!),
                          style: const TextStyle(
                            color: OdinTheme.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: OdinTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: OdinTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: OdinTheme.textTertiary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: OdinTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _handleAction(String action, String playerId) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerFormScreen(playerId: playerId),
          ),
        );
        break;
      case 'status':
        _showStatusDialog(playerId);
        break;
      case 'delete':
        _confirmDelete(playerId);
        break;
    }
  }

  void _showStatusDialog(String playerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['active', 'injured', 'suspended', 'inactive']
              .map((s) => ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: OdinTheme.statusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(s.toUpperCase()),
                    onTap: () {
                      Provider.of<PlayersProvider>(context, listen: false)
                          .updateStatus(playerId, s);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showPlayerSettingsDialog(dynamic player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OdinTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Paramètres',
              style: TextStyle(
                color: OdinTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: OdinTheme.primaryBlue,
                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Changer la photo de profil', style: TextStyle(color: OdinTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changement de photo bientôt disponible')));
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: OdinTheme.surfaceLight,
                child: const Icon(Icons.phone_rounded, color: OdinTheme.textSecondary, size: 20),
              ),
              title: const Text("Modifier contact d'urgence", style: TextStyle(color: OdinTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact sauvegardé')));
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: OdinTheme.surfaceLight,
                child: const Icon(Icons.notifications_active_rounded, color: OdinTheme.textSecondary, size: 20),
              ),
              title: const Text('Préférences de notification', style: TextStyle(color: OdinTheme.textPrimary)),
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeTrackColor: OdinTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String playerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le joueur ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final dialogNavigator = Navigator.of(ctx);
              await Provider.of<PlayersProvider>(context, listen: false)
                  .deletePlayer(playerId);
              if (mounted) {
                dialogNavigator.pop();
                navigator.pop();
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: OdinTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: OdinTheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
