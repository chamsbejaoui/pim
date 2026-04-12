import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/erp_access.dart';
import '../../providers/staff_provider.dart';
import '../../providers/teams_provider.dart';
import '../../../ui/shell/app_shell.dart';
import 'staff_detail_screen.dart';
import 'staff_form_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final _searchController = TextEditingController();
  String? _filterDepartment;
  String? _filterRole;
  String? _filterTeam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffProvider>(context, listen: false).fetchStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDepartment(String role) {
    final r = role.toLowerCase();
    if (r.contains('médecin') || r.contains('kiné') || r.contains('nutrition') || r.contains('médical')) return 'Médical';
    if (r.contains('recruteur') || r.contains('scout')) return 'Recrutement';
    if (r.contains('analyste') || r.contains('vidéo')) return 'Analyse';
    return 'Technique';
  }

  Color _getDeptColor(String dept) {
    switch (dept) {
      case 'Médical': return OdinTheme.accentGreen;
      case 'Recrutement': return OdinTheme.accentOrange;
      case 'Analyse': return OdinTheme.accentCyan;
      default: return OdinTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final teamsProvider = Provider.of<TeamsProvider>(context);
    final staff = provider.staffList.where((s) {
      final q = _searchController.text.toLowerCase();
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
      if (_filterDepartment != null && _getDepartment(s.role) != _filterDepartment) return false;
      if (_filterRole != null && s.role.toLowerCase() != _filterRole!.toLowerCase()) return false;
      if (_filterTeam != null && s.teamId != _filterTeam) return false;
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
                    child: const Icon(Icons.badge_rounded, color: OdinTheme.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gestion du Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Personnel administratif & technique',
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
                  _metricCard('TECH', provider.staffList.where((s) => _getDepartment(s.role) == 'Technique').length.toString(), Icons.sports_rounded, OdinTheme.primaryBlue),
                  const SizedBox(width: 12),
                  _metricCard('MED', provider.staffList.where((s) => _getDepartment(s.role) == 'Médical').length.toString(), Icons.medical_services_rounded, OdinTheme.accentGreen),
                  const SizedBox(width: 12),
                  _metricCard('RECRUT', provider.staffList.where((s) => _getDepartment(s.role) == 'Recrutement').length.toString(), Icons.search_rounded, OdinTheme.accentOrange),
                ],
              ),
            ),
          ),

          // ─── Main Content ──────────────────────────────────
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
                        'Staff (${staff.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StaffFormScreen(),
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
                          value: _filterRole,
                          hint: 'Tous rôles',
                          items: const ['admin', 'coach', 'medical', 'scout'],
                          itemLabels: const ['Admin', 'Entraîneur', 'Médical', 'Recruteur'],
                          onChanged: (v) => setState(() => _filterRole = v),
                        ),
                        const SizedBox(width: 12),
                        _filterDropdown<String?>(
                          value: _filterTeam,
                          hint: 'Toutes équipes',
                          items: teamsProvider.teams.map((t) => t.id).toList(),
                          itemLabels: teamsProvider.teams.map((t) => t.name).toList(),
                          onChanged: (v) => setState(() => _filterTeam = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Premium Staff Card List
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue)),
                    )
                  else if (staff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Aucun membre trouvé', style: TextStyle(color: OdinTheme.textTertiary))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staff.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildStaffCard(staff[i], isAdmin),
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

  Widget _buildStaffCard(dynamic staff, bool isAdmin) {
    final dept = _getDepartment(staff.role);
    final color = _getDeptColor(dept);

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
            Provider.of<StaffProvider>(context, listen: false).selectStaff(staff);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StaffDetailScreen(staffId: staff.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with Department Color Dot
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          staff.initials,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: OdinTheme.statusActive,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF111827), width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Name and Role Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dept.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              staff.role,
                              style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.email ?? 'Email non renseigné',
                        style: TextStyle(color: OdinTheme.textTertiary.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.edit_outlined,
                          color: OdinTheme.primaryBlue,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StaffFormScreen(staffId: staff.id),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          color: OdinTheme.accentRed,
                          onTap: () => _confirmDeleteStaff(staff.id, staff.fullName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.arrow_forward_ios_rounded, color: OdinTheme.textTertiary, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
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



  Widget _metricCard(String label, String value, IconData icon, Color color) {
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
            ...List.generate(items.length, (index) {
              final it = items[index];
              final label = itemLabels != null ? itemLabels[index] : it.toString();
              return DropdownMenuItem<T>(
                value: it,
                child: Text(label, style: const TextStyle(fontSize: 12)),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }


  void _confirmDeleteStaff(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OdinTheme.surface,
        title: const Text('Supprimer membre', style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer $name ?', style: const TextStyle(color: OdinTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final scaf = ScaffoldMessenger.of(context);
              final provider = Provider.of<StaffProvider>(context, listen: false);
              
              final success = await provider.deleteStaff(id);
              
              nav.pop();
              scaf.showSnackBar(
                SnackBar(content: Text(success ? 'Membre supprimé' : 'Erreur de suppression')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: OdinTheme.accentRed),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
