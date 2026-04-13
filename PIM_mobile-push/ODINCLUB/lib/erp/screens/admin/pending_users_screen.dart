import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class PendingUsersScreen extends StatefulWidget {
  const PendingUsersScreen({super.key});

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    Color(0xFF2C3E50),
                    Color(0xFF1A1A2E),
                    Colors.black,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: OdinTheme.primaryBlue, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Validations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Demandes d’inscription en attente',
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
          Consumer<AdminProvider>(
            builder: (context, admin, child) {
              if (admin.isLoading && admin.pendingUsers.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue)),
                );
              }

              if (admin.error != null && admin.pendingUsers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: OdinTheme.accentRed, size: 48),
                        const SizedBox(height: 16),
                        Text('Erreur: ${admin.error}', style: const TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () => admin.fetchPendingUsers(),
                          child: const Text('RÉESSAYER'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (admin.pendingUsers.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, color: OdinTheme.textSecondary, size: 64),
                        SizedBox(height: 16),
                        Text('Aucune demande en attente', 
                          style: TextStyle(color: OdinTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = admin.pendingUsers[index];
                      return _UserApprovalCard(user: user);
                    },
                    childCount: admin.pendingUsers.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserApprovalCard extends StatelessWidget {
  final dynamic user;

  const _UserApprovalCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: OdinTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: OdinTheme.primaryBlue.withValues(alpha: 0.2),
              child: Text(
                '${user['firstName']?[0] ?? ''}${user['lastName']?[0] ?? ''}',
                style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('${user['firstName']} ${user['lastName']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user['email'] ?? '', style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: OdinTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user['role']?.toUpperCase() ?? '',
                    style: const TextStyle(color: OdinTheme.accentOrange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectDialog(context),
                  child: const Text('REJETER', style: TextStyle(color: OdinTheme.accentRed)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OdinTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('APPROUVER'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _approveUser(BuildContext context) async {
    final result = await context.read<AdminProvider>().approveUser(user['id']);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? OdinTheme.accentGreen : OdinTheme.accentRed,
        ),
      );
    }
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OdinTheme.surfaceLight,
        title: const Text('Rejeter la demande', style: TextStyle(color: Colors.white)),
        content: const Text('Êtes-vous sûr de vouloir rejeter cette demande d\'adhésion ?', 
          style: TextStyle(color: OdinTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Provider.of<AdminProvider>(context, listen: false).rejectUser(user['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? OdinTheme.accentGreen : OdinTheme.accentRed,
                  ),
                );
              }
            },
            child: const Text('REJETER', style: TextStyle(color: OdinTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}
