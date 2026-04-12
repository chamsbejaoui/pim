import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/erp_access.dart';
import '../../providers/players_provider.dart';
import '../../providers/teams_provider.dart';
import '../../../ui/shell/app_shell.dart';
import 'player_detail_screen.dart';
import 'player_form_screen.dart';

class PlayersListScreen extends StatefulWidget {
  const PlayersListScreen({super.key});

  @override
  State<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends State<PlayersListScreen> {
  final _searchController = TextEditingController();
  String? _filterStatus;
  String? _filterPosition;
  String? _filterTeam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayersProvider>(context, listen: false).fetchPlayers();
      Provider.of<TeamsProvider>(context, listen: false).fetchTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayersProvider>(context);
    final teamsProvider = Provider.of<TeamsProvider>(context);
    final players = provider.players.where((p) {
      final q = _searchController.text.toLowerCase();
      if (q.isNotEmpty && !p.fullName.toLowerCase().contains(q)) return false;
      if (_filterStatus != null && p.status != _filterStatus) return false;
      if (_filterPosition != null && p.position != _filterPosition) return false;
      if (_filterTeam != null && p.teamId != _filterTeam) return false;
      return true;
    }).toList();

    final session = AppShellScope.of(context)?.session;
    final isAdmin = erpIsAdminRole(session?.role);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E293B), // Deep blue-gray
                    Color(0xFF0F172A), // Dark navy
                    Color(0xFF020617), // Pure black
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.groups_rounded, color: OdinTheme.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gestion des Joueurs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Effectif complet • Base de données admin',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Metrics Bar ───────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _metricCard('TOTAL', provider.players.length.toString(), 'Joueurs', Icons.sports_soccer_rounded, OdinTheme.primaryBlue),
                  const SizedBox(width: 12),
                  _metricCard('ACTIFS', provider.players.where((p) => p.status == 'active').length.toString(), 'Dispo', Icons.check_rounded, OdinTheme.accentGreen),
                  const SizedBox(width: 12),
                  _metricCard('BLESSÉS', provider.players.where((p) => p.status == 'injured').length.toString(), 'Indispo', Icons.medical_services_rounded, OdinTheme.accentRed),
                  const SizedBox(width: 12),
                  _metricCard('SUSPENDUS', provider.players.where((p) => p.status == 'suspended').length.toString(), 'Suivi', Icons.warning_rounded, OdinTheme.accentOrange),
                ],
              ),
            ),
          ),

          // ─── Filters & Main Content ────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Effectif (${players.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlayerFormScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OdinTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 8,
                            shadowColor: OdinTheme.primaryBlue.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Search & Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Rechercher...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: OdinTheme.textTertiary),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _filterDropdown<String?>(
                          value: _filterPosition,
                          hint: 'Tous postes',
                          items: const ['Gardien', 'Défenseur', 'Milieu', 'Attaquant'],
                          onChanged: (v) => setState(() => _filterPosition = v),
                        ),
                        const SizedBox(width: 12),
                        _filterDropdown<String?>(
                          value: _filterTeam,
                          hint: 'Toutes équipes',
                          items: teamsProvider.teams.map((t) => t.id).toList(),
                          itemLabels: teamsProvider.teams.map((t) => t.name).toList(),
                          onChanged: (v) => setState(() => _filterTeam = v),
                        ),
                        const SizedBox(width: 12),
                        _filterDropdown<String?>(
                          value: _filterStatus,
                          hint: 'Tous statuts',
                          items: const ['active', 'injured', 'suspended', 'inactive'],
                          itemLabels: const ['Actif', 'Blessé', 'Suspendu', 'Inactif'],
                          onChanged: (v) => setState(() => _filterStatus = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Premium Card List
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue)),
                    )
                  else if (players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Aucun joueur trouvé', style: TextStyle(color: OdinTheme.textTertiary))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildPlayerCard(players[i], isAdmin),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildPlayerCard(dynamic player, bool isAdmin) {
    final statusColors = {
      'active': OdinTheme.accentGreen,
      'injured': OdinTheme.accentRed,
      'suspended': OdinTheme.accentOrange,
      'rehab': OdinTheme.accentPurple,
    };
    final accentColor = statusColors[player.status] ?? OdinTheme.primaryBlue;
    
    // Status Labels inspired by user screenshot
    String statusLabel = 'READY';
    if (player.status == 'injured') statusLabel = 'DISABLED';
    if (player.status == 'suspended') statusLabel = 'PENDING';
    if (player.status == 'rehab') statusLabel = 'WARMUP';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<PlayersProvider>(context, listen: false).selectPlayer(player);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(playerId: player.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with Status Dot
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: OdinTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        image: player.photoUrl != null 
                          ? DecorationImage(image: NetworkImage(player.photoUrl!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: player.photoUrl == null 
                        ? Center(child: Text(player.initials, style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20)))
                        : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF111827), width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Name and Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.teamName ?? 'Elite Academy'} • ${player.position}',
                        style: const TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Specific stats display from screenshot
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Prev: ', style: TextStyle(color: OdinTheme.textTertiary.withValues(alpha: 0.5), fontSize: 12)),
                          Text('${player.stats?['prev_sprint'] ?? '4.2s'}', style: const TextStyle(color: OdinTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(' • ', style: TextStyle(color: OdinTheme.textTertiary.withValues(alpha: 0.5))),
                          Text('Target: ', style: TextStyle(color: OdinTheme.textTertiary.withValues(alpha: 0.5), fontSize: 12)),
                          Text('${player.stats?['target_sprint'] ?? '4.1s'}', style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isAdmin)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _actionButton(
                            icon: Icons.edit_outlined,
                            color: OdinTheme.primaryBlue,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerFormScreen(playerId: player.id),
                              ),
                            );
                          },
                          ),
                          const SizedBox(width: 8),
                          _actionButton(
                            icon: Icons.delete_outline_rounded,
                            color: OdinTheme.accentRed,
                            onTap: () => _confirmDeletePlayer(player.id, player.fullName),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Icon(Icons.arrow_forward_ios_rounded, color: OdinTheme.textTertiary, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _metricCard(String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OdinTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OdinTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              Icon(icon, color: OdinTheme.textTertiary.withValues(alpha: 0.3), size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (label == 'ACTIFS') Icon(Icons.arrow_upward_rounded, color: color, size: 10),
              if (label == 'BLESSÉS') Icon(Icons.arrow_downward_rounded, color: color, size: 10),
              const SizedBox(width: 2),
              Text(subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required String hint,
    required List<T> items,
    List<String>? itemLabels,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141A2B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 12)),
          underline: const SizedBox(),
          isExpanded: true,
          dropdownColor: OdinTheme.surfaceLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: OdinTheme.textTertiary, size: 18),
          items: [
            DropdownMenuItem<T>(value: null, child: Text(hint, style: const TextStyle(fontSize: 12))),
            ...List.generate(items.length, (i) {
              return DropdownMenuItem<T>(
                value: items[i],
                child: Text(itemLabels != null ? itemLabels[i] : items[i].toString(), style: const TextStyle(fontSize: 12)),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _confirmDeletePlayer(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OdinTheme.surface,
        title: const Text('Supprimer joueur', style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer $name ?', style: const TextStyle(color: OdinTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final scaf = ScaffoldMessenger.of(context);
              final provider = Provider.of<PlayersProvider>(context, listen: false);
              
              final success = await provider.deletePlayer(id);
              
              nav.pop();
              scaf.showSnackBar(
                SnackBar(content: Text(success ? 'Joueur supprimé' : 'Erreur de suppression')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: OdinTheme.accentRed),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
