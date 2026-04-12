import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/erp_access.dart';
import '../../providers/staff_provider.dart';
import '../../../ui/shell/app_shell.dart';
import 'staff_form_screen.dart';

class StaffDetailScreen extends StatefulWidget {
  final String? staffId;
  const StaffDetailScreen({super.key, this.staffId});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final session = AppShellScope.of(context)?.session;
      final id = widget.staffId ?? session?.userId;
      
      if (id != null) {
        Provider.of<StaffProvider>(context, listen: false).fetchStaffMember(id);
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final staff = provider.selectedStaff;

    if (provider.error != null && staff == null) {
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
                  final id = widget.staffId ?? session?.userId;
                  if (id != null) provider.fetchStaffMember(id);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if ((provider.isLoading && staff == null) || staff == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: OdinTheme.primaryBlue),
        ),
      );
    }

    final dept = _getDepartment(staff.role);
    final color = _getDeptColor(dept);
    final session = AppShellScope.of(context)?.session;
    final isAdmin = erpIsAdminRole(session?.role);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: OdinTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.8),
                      OdinTheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          staff.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          dept.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StaffFormScreen(staffId: staff.id),
                      ),
                    );
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Informations Professionnelles', [
                    _infoRow('Rôle', staff.role),
                    _infoRow('Email', staff.email ?? 'Non renseigné'),
                    _infoRow('Téléphone', staff.phone ?? 'Non renseigné'),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Équipe & Affectation', [
                    _infoRow('Équipe', staff.teamName ?? 'Non assigné'),
                  ]),
                  if (staff.bio != null && staff.bio!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection('Biographie', [
                      Text(
                        staff.bio!,
                        style: const TextStyle(color: OdinTheme.textSecondary, height: 1.5),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: OdinTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: OdinTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 13)),
          Text(value, style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
