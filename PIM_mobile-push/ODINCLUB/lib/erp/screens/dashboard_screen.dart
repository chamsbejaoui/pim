import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/players_provider.dart';
import '../providers/staff_provider.dart';
import '../providers/events_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final players = Provider.of<PlayersProvider>(context, listen: false);
    final staff = Provider.of<StaffProvider>(context, listen: false);
    final events = Provider.of<EventsProvider>(context, listen: false);
    final notifs = Provider.of<NotificationsProvider>(context, listen: false);

    players.fetchPlayers();
    staff.fetchStaff();
    events.fetchEvents();
    notifs.fetchNotifications();
    
    final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
    if (role == 'admin' || role == 'responsable') {
      Provider.of<AdminProvider>(context, listen: false).fetchPendingUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auth provider
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.user?.role;
    
    final players = Provider.of<PlayersProvider>(context);
    final staff = Provider.of<StaffProvider>(context);
    final events = Provider.of<EventsProvider>(context);
    final notifs = Provider.of<NotificationsProvider>(context);
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: OdinTheme.primaryBlue,
          backgroundColor: OdinTheme.surface,
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top bar ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: OdinTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Odin ERP',
                              style: TextStyle(
                                color: OdinTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UNIFIED HUB',
                          style: TextStyle(
                            color: OdinTheme.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search_rounded,
                              color: OdinTheme.textSecondary),
                          onPressed: () {},
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: OdinTheme.textSecondary),
                              onPressed: () => context.push('/notifications'),
                            ),
                            if (notifs.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: OdinTheme.accentRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${notifs.unreadCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: OdinTheme.accentRed),
                          onPressed: () => _confirmLogout(context, auth),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Quick nav pills ───────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (role != 'player')
                        _buildPill(Icons.people_rounded, 'Squad',
                            () => context.push('/players')),
                      if (role != 'player')
                        _buildPill(Icons.badge_rounded, 'Staff',
                            () => context.push('/staff')),
                      _buildPill(Icons.calendar_month_rounded, 'Events',
                          () => context.push('/events')),
                      if (role != 'player')
                        _buildPill(Icons.psychology_rounded, 'AI Readiness',
                            () => context.push('/readiness'),
                            isPrimary: true),
                      if (role != 'player')
                        _buildPill(Icons.groups_rounded, 'Teams',
                            () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("L'affectation aux équipes se fait dans la fiche joueur !")))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── AI Readiness Banner ───────────────────────
                if (role != 'player')
                  GestureDetector(
                    onTap: () => context.push('/readiness'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.psychology_rounded,
                                color: Color(0xFFA5B4FC), size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '🤖  AI Match Readiness',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'NOUVEAU',
                                      style: TextStyle(
                                        color: Color(0xFF818CF8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Analyse Gemini AI — Score de disponibilité 0–100 par joueur',
                                  style: TextStyle(
                                      color: Color(0xFF818CF8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF818CF8), size: 14),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ─── Upcoming events ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UPCOMING EVENTS',
                      style: TextStyle(
                        color: OdinTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/events'),
                      child: Text(
                        'View Calendar',
                        style: TextStyle(
                          color: OdinTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (events.events.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: events.events.take(3).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final ev = events.events[i];
                        return _buildEventCard(ev);
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: OdinTheme.glassCard,
                    child: const Text(
                      'Aucun événement à venir',
                      style: TextStyle(color: OdinTheme.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // ─── Stats ─────────────────────────────────────
                const Text(
                  'LIVE NERVE CENTER',
                  style: TextStyle(
                    color: OdinTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      title: 'Active Squad',
                      value: '${players.players.where((p) => p.status == 'active').length}',
                      icon: Icons.people_rounded,
                      accentColor: OdinTheme.primaryBlue,
                      subtitle: '${players.totalCount} total',
                    ),
                    StatCard(
                      title: 'Staff Members',
                      value: '${staff.staffList.length}',
                      icon: Icons.badge_rounded,
                      accentColor: OdinTheme.accentPurple,
                    ),
                    StatCard(
                      title: 'Events',
                      value: '${events.events.length}',
                      icon: Icons.calendar_month_rounded,
                      accentColor: OdinTheme.accentCyan,
                    ),
                    StatCard(
                      title: 'Notifications',
                      value: '${notifs.unreadCount}',
                      icon: Icons.notifications_rounded,
                      accentColor: OdinTheme.accentOrange,
                      subtitle: 'non lues',
                    ),
                    if (role == 'admin' || role == 'responsable')
                      StatCard(
                        title: 'Validations',
                        value: '${admin.pendingUsers.length}',
                        icon: Icons.how_to_reg_rounded,
                        accentColor: OdinTheme.accentGreen,
                        subtitle: 'en attente',
                        onTap: () => context.push('/admin/pending-users'),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Recent players ────────────────────────────
                const Text(
                  'RECENT SQUAD',
                  style: TextStyle(
                    color: OdinTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...players.players.take(4).map((p) => _buildRecentTile(
                  context,
                  id: p.id,
                  initials: p.initials,
                  name: p.fullName,
                  subtitle: '${p.position} • #${p.jerseyNumber ?? '-'}',
                  status: p.status,
                  isPlayer: true,
                )),

                if (role != 'player') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'RECENT STAFF',
                    style: TextStyle(
                      color: OdinTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (staff.staffList.isNotEmpty)
                    ...staff.staffList.take(4).map((s) => _buildRecentTile(
                      context,
                      id: s.id,
                      initials: s.initials,
                      name: s.fullName,
                      subtitle: s.role,
                      status: 'active', // Staff usually active if in list
                      isPlayer: false,
                    ))
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: OdinTheme.glassCard,
                      child: const Text(
                        'Aucun membre du staff trouvé',
                        style: TextStyle(color: OdinTheme.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                const SizedBox(height: 80), // bottom nav padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, VoidCallback onTap, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary ? OdinTheme.primaryBlue.withValues(alpha: 0.1) : OdinTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? OdinTheme.primaryBlue.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
              width: isPrimary ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isPrimary ? OdinTheme.primaryBlue : OdinTheme.textSecondary,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? OdinTheme.primaryBlue : OdinTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic ev) {
    final colors = {
      'match': OdinTheme.accentRed,
      'entrainement': OdinTheme.accentGreen,
      'reunion': OdinTheme.accentOrange,
      'detection': OdinTheme.accentCyan,
      'test_physique': OdinTheme.accentPurple,
    };
    final color = colors[ev.eventType] ?? OdinTheme.primaryBlue;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: OdinTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ev.eventTypeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            ev.title,
            style: const TextStyle(
              color: OdinTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 12, color: OdinTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${ev.startDate.hour.toString().padLeft(2, '0')}:${ev.startDate.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: OdinTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
              if (ev.location != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.location_on_rounded,
                    size: 12, color: OdinTheme.textTertiary),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    ev.location,
                    style: const TextStyle(
                      color: OdinTheme.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTile(
    BuildContext context, {
    required String id,
    required String initials,
    required String name,
    required String subtitle,
    required String status,
    required bool isPlayer,
  }) {
    final accentColor = isPlayer ? OdinTheme.primaryBlue : OdinTheme.accentPurple;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: OdinTheme.glassCard,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accentColor.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: OdinTheme.statusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(color: OdinTheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: OdinTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OdinTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(
                icon: Icons.edit_outlined,
                color: OdinTheme.primaryBlue,
                onTap: () => context.push(
                  isPlayer ? '/players/form' : '/staff/form',
                  extra: id,
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.delete_outline_rounded,
                color: OdinTheme.accentRed,
                onTap: () => _confirmDelete(context, id, name, isPlayer),
              ),
            ],
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
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name, bool isPlayer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OdinTheme.surface,
        title: Text(isPlayer ? 'Supprimer joueur' : 'Supprimer membre',
            style: const TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer $name ?',
            style: const TextStyle(color: OdinTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final scaf = ScaffoldMessenger.of(context);
              bool success = false;
              
              if (isPlayer) {
                success = await Provider.of<PlayersProvider>(context, listen: false).deletePlayer(id);
              } else {
                success = await Provider.of<StaffProvider>(context, listen: false).deleteStaff(id);
              }
              
              nav.pop();
              scaf.showSnackBar(
                SnackBar(content: Text(success ? 'Supprimé avec succès' : 'Erreur de suppression')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: OdinTheme.accentRed),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OdinTheme.surface,
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: OdinTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: OdinTheme.accentRed),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
