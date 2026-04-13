import 'package:flutter/material.dart';

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../components/empty_state.dart';
import '../shell/app_shell.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserManagementApi _api = UserManagementApi();

  bool _loading = false;
  String? _error;
  String? _activeActionUserId;
  String? _loadedToken;
  List<UserModel> _pendingUsers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = AppShellScope.of(context)?.session.token;
    if (token != null && token != _loadedToken) {
      _loadedToken = token;
      _loadPendingUsers();
    }
  }

  Future<void> _loadPendingUsers() async {
    final scope = AppShellScope.of(context);
    if (scope == null) {
      if (mounted) {
        setState(() => _error = 'Session unavailable. Please re-login.');
      }
      return;
    }

    final session = scope.session;
    if (session.role != 'ADMIN') {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _api.getPendingUsers(session.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingUsers = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _approveOrReject(UserModel user, bool approve) async {
    final scope = AppShellScope.of(context);
    if (scope == null) {
      return;
    }

    setState(() => _activeActionUserId = user.id);

    try {
      await _api.approveUser(
        scope.session.token,
        user.id,
        approve,
        asAdmin: true,
      );
      if (mounted) {
        final message = approve
            ? '${user.fullName} approved.'
            : '${user.fullName} rejected.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      await _loadPendingUsers();
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
        setState(() => _activeActionUserId = null);
      }
    }
  }

  String _roleLabel(String role) {
    return role.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppShellScope.of(context);
    if (scope == null) {
      return const EmptyState(
        title: 'Session unavailable',
        message: 'Please login again to continue.',
        icon: Icons.error_outline_rounded,
      );
    }

    if (scope.session.role != 'ADMIN') {
      return const EmptyState(
        title: 'Access restricted',
        message: 'This page is reserved for ADMIN users.',
        icon: Icons.lock_outline_rounded,
      );
    }

    if (_loading && _pendingUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _pendingUsers.isEmpty) {
      return EmptyState(
        title: 'Unable to load pending users',
        message: _error,
        icon: Icons.error_outline_rounded,
        action: FilledButton.icon(
          onPressed: _loadPendingUsers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }

    if (_pendingUsers.isEmpty) {
      return EmptyState(
        title: 'No pending admin approvals',
        message: 'All accounts requiring admin validation are processed.',
        icon: Icons.verified_user_outlined,
        action: FilledButton.icon(
          onPressed: _loadPendingUsers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pending Admin Approvals (${_pendingUsers.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _loadPendingUsers,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPendingUsers,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _pendingUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _pendingUsers[index];
                final busy = _activeActionUserId == user.id;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.fullName.trim().isEmpty
                            ? 'U'
                            : user.fullName.trim()[0].toUpperCase(),
                      ),
                    ),
                    title: Text(user.fullName.trim().isEmpty
                        ? user.email
                        : user.fullName),
                    subtitle: Text(
                      '${user.email}\nRole: ${_roleLabel(user.role)} • Status: ${user.status}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _approveOrReject(user, false),
                          child: const Text('Reject'),
                        ),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => _approveOrReject(user, true),
                          child: busy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Approve'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
