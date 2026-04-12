import 'package:flutter/material.dart';

import '../../finance/theme/finance_theme.dart';
import '../api/user_management_api.dart';
import '../models/user_management_models.dart';

class ResponsableApprovalMobilePage extends StatefulWidget {
  const ResponsableApprovalMobilePage({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
    required this.onOpenMessages,
  });

  final UserManagementApi api;
  final SessionModel? session;
  final VoidCallback onLogout;
  final VoidCallback onOpenMessages;

  @override
  State<ResponsableApprovalMobilePage> createState() =>
      _ResponsableApprovalMobilePageState();
}

class _ResponsableApprovalMobilePageState
    extends State<ResponsableApprovalMobilePage> {
  static const List<String> _roleFilters = [
    'ALL',
    'JOUEUR',
    'STAFF_TECHNIQUE',
    'STAFF_MEDICAL',
    'FINANCIER',
    'SCOUT',
  ];

  bool _loading = false;
  String? _error;
  String? _actionUserId;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'ALL';
  List<UserModel> _pending = [];
  List<UserModel> _users = [];

  @override
  void didUpdateWidget(covariant ResponsableApprovalMobilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session?.token != widget.session?.token) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = widget.session;
    if (session == null || session.role != 'CLUB_RESPONSABLE') {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pending = await widget.api.getPendingUsers(session.token);
      final users = await widget.api.getUsers(session.token);
      if (mounted) {
        setState(() {
          _pending = pending;
          _users = users;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _approve(UserModel user, bool approve) async {
    final session = widget.session;
    if (session == null) {
      return;
    }

    setState(() => _actionUserId = user.id);

    try {
      await widget.api.approveUser(session.token, user.id, approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? '${user.fullName} approuve.'
                  : '${user.fullName} rejete.',
            ),
          ),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionUserId = null);
      }
    }
  }

  bool _matchesFilters(UserModel user) {
    final roleOk = _selectedRole == 'ALL' || user.role == _selectedRole;
    if (!roleOk) {
      return false;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final fullName = user.fullName.toLowerCase();
    final email = user.email.toLowerCase();
    final role = user.role.toLowerCase();
    return fullName.contains(query) ||
        email.contains(query) ||
        role.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = FinancePalette.muted;

    final session = widget.session;

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous pour gerer les utilisateurs du club.'),
        ),
      );
    }

    if (session.role != 'CLUB_RESPONSABLE') {
      return Scaffold(
        appBar: AppBar(title: const Text('Validation utilisateurs')),
        body: Center(
          child: Text(
            'Role connecte: ${session.role}. Cette section est reservee au CLUB_RESPONSABLE.',
          ),
        ),
      );
    }

    final filteredPending = _pending.where(_matchesFilters).toList();
    final filteredUsers = _users.where(_matchesFilters).toList();
    final activeUsers = _users.where((u) => u.status == 'ACTIVE').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FinancePalette.navy, FinancePalette.scaffold],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: _orb(
                260,
                FinancePalette.blue.withValues(alpha: dark ? 0.14 : 0.09),
              ),
            ),
            Positioned(
              bottom: -180,
              right: -120,
              child: _orb(
                340,
                FinancePalette.cyan.withValues(alpha: dark ? 0.07 : 0.05),
              ),
            ),
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 50),
                              Expanded(
                                child: Text(
                                  'Approve User Requests',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh',
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                              IconButton(
                                tooltip: 'Messages',
                                onPressed: widget.onOpenMessages,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Notifications',
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Validation des inscriptions du club',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: subtitleColor),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Pending Requests',
                                  value: '${_pending.length}',
                                  trend: 'Awaiting decision',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Approved Users',
                                  value: '$activeUsers',
                                  trend: 'Active in club',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _StatCard(
                            label: 'Total Club Users',
                            value: '${_users.length}',
                            trend: 'Registered users',
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Search & Filter',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name, email, role',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Role filter',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  items: _roleFilters
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(
                                      () => _selectedRole = value ?? 'ALL',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Approvals (${filteredPending.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                if (filteredPending.isEmpty)
                                  const Text(
                                    'No pending registration requests for current filter.',
                                  ),
                                ...filteredPending.map(
                                  (user) => _PendingUserCard(
                                    user: user,
                                    loading: _actionUserId == user.id,
                                    onApprove: () => _approve(user, true),
                                    onReject: () => _approve(user, false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Club Users List (${filteredUsers.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                if (filteredUsers.isEmpty)
                                  const Text('No users found for this filter.'),
                                ...filteredUsers.map(
                                  (user) => _UserRow(user: user),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: FinancePalette.muted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live',
            style: TextStyle(
              color: Color(0xFF13A16D),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            trend,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: FinancePalette.muted),
          ),
        ],
      ),
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  const _PendingUserCard({
    required this.user,
    required this.loading,
    required this.onApprove,
    required this.onReject,
  });

  final UserModel user;
  final bool loading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft.withValues(
          alpha: FinancePalette.isDark ? 0.65 : 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Role: ${user.role} • ${user.email}'),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: loading ? null : onReject,
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: loading ? null : onApprove,
                child: Text(loading ? 'Saving...' : 'Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (user.status) {
      'ACTIVE' => FinancePalette.success,
      'REJECTED' => FinancePalette.danger,
      _ => FinancePalette.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft.withValues(
          alpha: FinancePalette.isDark ? 0.65 : 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('${user.role} • ${user.email}'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Text(
              user.status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
