import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/role_mapper.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  List<dynamic> _pendingUsers = [];
  List<dynamic> _allUsers = [];
  bool _isLoadingPending = false;
  bool _isLoadingAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingUsers();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoadingPending = true;
    });

    final result = await _apiService.getPendingUsers();
    
    setState(() {
      _isLoadingPending = false;
    });

    if (result['success'] && mounted) {
      setState(() {
        _pendingUsers = result['data']['users'] ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to load pending users'),
          backgroundColor: AppTheme.blueFonce,
        ),
      );
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoadingAll = true;
    });

    final result = await _apiService.getAllUsers();
    
    setState(() {
      _isLoadingAll = false;
    });

    if (result['success'] && mounted) {
      setState(() {
        _allUsers = result['data']['users'] ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to load users'),
          backgroundColor: AppTheme.blueFonce,
        ),
      );
    }
  }

  Future<void> _approveUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Are you sure you want to approve $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.approveUser(userId);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User approved successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      _loadPendingUsers();
      _loadAllUsers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to approve user'),
          backgroundColor: AppTheme.blueFonce,
        ),
      );
    }
  }

  Future<void> _rejectUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Are you sure you want to reject $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blueFonce,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.rejectUser(userId);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User rejected successfully'),
          backgroundColor: AppTheme.blueCiel,
        ),
      );
      _loadPendingUsers();
      _loadAllUsers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject user'),
          backgroundColor: AppTheme.blueFonce,
        ),
      );
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool showActions = false}) {
    final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final email = user['email'] ?? '';
    final role = user['role'] ?? '';
    final roleCode = RoleMapper.normalize(role);
    final roleLabel = RoleMapper.toLabel(roleCode);
    final isApproved = user['isApprovedByAdmin'] ?? false;
    final isActive = user['isActive'] ?? false;
    final isEmailVerified = user['isEmailVerified'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(roleCode).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(roleCode),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip('Email Verified', isEmailVerified, AppTheme.blueCiel),
                const SizedBox(width: 8),
                _buildStatusChip('Approved', isApproved, AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _buildStatusChip('Active', isActive, AppTheme.blueFonce),
              ],
            ),
            if (showActions && !isApproved) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _rejectUser(user['id'], fullName),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.blueFonce,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveUser(user['id'], fullName),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? color : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppTheme.blueFonce;
      case 'CLUB_RESPONSABLE':
        return AppTheme.blueCiel;
      case 'STAFF_TECHNIQUE':
        return AppTheme.blueCiel;
      case 'SCOUT':
        return AppTheme.blueCiel;
      case 'FINANCIER':
        return AppTheme.blueFonce;
      case 'JOUEUR':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending Approval',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'All Users',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientDecoration,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Pending Users Tab
            _isLoadingPending
                ? const Center(child: CircularProgressIndicator())
                : _pendingUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending users',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.darkGrey.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPendingUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _pendingUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(
                              Map<String, dynamic>.from(_pendingUsers[index]),
                              showActions: true,
                            );
                          },
                        ),
                      ),

            // All Users Tab
            _isLoadingAll
                ? const Center(child: CircularProgressIndicator())
                : _allUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.darkGrey.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _allUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(
                              Map<String, dynamic>.from(_allUsers[index]),
                              showActions: false,
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
