import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'login_screen.dart';
import 'account_settings_screen.dart';
import 'players/players_list_view.dart';
import 'coaches/coaches_list_view.dart';
import '../utils/role_mapper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  
  List<dynamic> _pendingUsers = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoadingPending = false;
  bool _isLoadingAll = false;
  String? _userRole;
  
  // Filters
  String? _selectedRoleFilter;
  String? _selectedPositionFilter;
  
  final List<String> _roles = [
    'All',
    ...RoleMapper.labels,
  ];
  
  final List<String> _positions = [
    'All',
    'Gardien',
    'Défenseur',
    'Milieu',
    'Attaquant',
  ];

  double _scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = width / 390.0;
    return scale.clamp(0.85, 1.2);
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 900;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Auto-refresh every 30 seconds
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadPendingUsers();
        _loadAllUsers();
        _startAutoRefresh();
      }
    });
  }

  bool get _isAdmin => RoleMapper.isAdmin(_userRole);
  bool get _isManager =>
      RoleMapper.isAdmin(_userRole) || RoleMapper.normalize(_userRole) == 'CLUB_RESPONSABLE';

  Future<void> _handleLogout() async {
    await _apiService.removeToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadProfile() async {
    final result = await _apiService.getUserProfile();
    if (result['success'] && mounted) {
      setState(() {
        _userRole = result['data']['role'];
      });
      if (_isAdmin) {
        _loadPendingUsers();
        _loadAllUsers();
      }
    }
  }

  Future<void> _loadPendingUsers() async {
    if (!_isAdmin) return;
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
    if (!_isAdmin) return;
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
        _applyFilters();
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

  void _applyFilters() {
    List<dynamic> filtered = List.from(_allUsers);
    
    if (_selectedRoleFilter != null && _selectedRoleFilter != 'All') {
      final selectedCode = RoleMapper.toCode(_selectedRoleFilter!);
      filtered = filtered
          .where((u) => RoleMapper.normalize(u['role']?.toString()) == selectedCode)
          .toList();
    }
    
    if (_selectedPositionFilter != null && _selectedPositionFilter != 'All') {
      filtered = filtered.where((u) => u['position'] == _selectedPositionFilter).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  Future<void> _approveUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve User'),
        content: Text('Are you sure you want to approve $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blueFonce,
            ),
            child: Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.approveUser(userId);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User approved successfully'),
          backgroundColor: AppTheme.blueFonce,
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
        title: Text('Reject User'),
        content: Text('Are you sure you want to reject $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blueFonce,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.rejectUser(userId);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User rejected successfully'),
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

  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarExpanded ? 250.0 : 70.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.blueFonce,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: EdgeInsets.all(_isSidebarExpanded ? 20 : 16),
            decoration: BoxDecoration(
              color: AppTheme.blueFonce.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.blueCiel.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ODIN Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSidebarExpanded = !_isSidebarExpanded;
                    });
                  },
                  tooltip: _isSidebarExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
          ),
          
          // Notification badge for pending users
          if (_pendingUsers.isNotEmpty && _isSidebarExpanded)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.blueCiel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_pendingUsers.length} pending',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                if (_isAdmin) ...[
                  _buildMenuItem(
                    icon: Icons.pending_actions,
                    title: 'Pending Approval',
                    index: 1,
                    badge: _pendingUsers.isNotEmpty ? _pendingUsers.length : null,
                  ),
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'All Users',
                    index: 2,
                  ),
                ],
                if (_isManager) ...[
                  _buildMenuItem(
                    icon: Icons.sports_soccer,
                    title: 'Players',
                    index: 3,
                  ),
                  _buildMenuItem(
                    icon: Icons.sports,
                    title: 'Coaches',
                    index: 4,
                  ),
                ],
                const Divider(color: Colors.white24, height: 32),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  index: 5,
                  enabled: false,
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: 'Reports',
                  index: 6,
                  enabled: false,
                ),
                const Divider(color: Colors.white24, height: 32),
                ListTile(
                  leading: Icon(Icons.settings, color: AppTheme.blueCiel, size: 24),
                  title: Text(
                    'Account & Settings',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade300, size: 24),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: _isSidebarExpanded
                ? Text(
                    'ODIN Club',
                    style: TextStyle(
                      color: AppTheme.blueCiel,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Icon(
                    Icons.sports_soccer,
                    color: AppTheme.blueCiel,
                    size: 24,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    bool enabled = true,
    int? badge,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.blueCiel.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppTheme.blueCiel.withOpacity(0.5), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (isSelected ? AppTheme.blueCiel : Colors.white70)
                  : Colors.white30,
              size: 24,
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.blueCiel,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: TextStyle(
                  color: enabled
                      ? (isSelected ? Colors.white : Colors.white70)
                      : Colors.white30,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              )
            : null,
        enabled: enabled,
        onTap: enabled
            ? () {
                setState(() {
                  _selectedIndex = index;
                });
              }
            : null,
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_userRole == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isManager) {
      return Center(
        child: Text(
          'Access restricted',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
      );
    }
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _isAdmin ? _buildPendingUsersView() : _buildDashboardOverview();
      case 2:
        return _isAdmin ? _buildAllUsersView() : _buildDashboardOverview();
      case 3:
        return const PlayersListView();
      case 4:
        return const CoachesListView();
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    final scale = _scale(context);
    final totalUsers = _allUsers.length;
    final pendingCount = _pendingUsers.length;
    final approvedCount = _allUsers.where((u) => u['isApprovedByAdmin'] == true).length;
    final healthyPct = totalUsers > 0 ? ((approvedCount / totalUsers) * 100).round() : 0;

    final isMobile = _isMobileLayout(context);
    return Container(
      color: AppTheme.lightGrey,
      child: Column(
        children: [
          if (!isMobile) _buildUnifiedHubAppBar(scale),
          _buildQuickAccessRow(scale),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20 * scale, 16 * scale, 20 * scale, 100 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('UPCOMING EVENTS', 'View Calendar', () {}),
                  SizedBox(height: 12 * scale),
                  _buildEventCard(
                    title: 'MATCH DAY • UEFA CL vs Manchester City',
                    subtitle: '20:45 • Etihad Stadium',
                    icon: Icons.stadium,
                    onTap: () {},
                  ),
                  SizedBox(height: 8 * scale),
                  _buildEventCard(
                    title: 'CONTRACT EXPIRY • Smith',
                    subtitle: 'Tomorrow',
                    icon: Icons.calendar_today,
                    onTap: () {},
                  ),
                  SizedBox(height: 24 * scale),
                  _buildSectionHeader('LIVE NERVE CENTER', null, null),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNerveCard(
                          icon: Icons.groups,
                          change: '+${totalUsers > 0 ? ((approvedCount / totalUsers) * 100).round() : 0}%',
                          changePositive: true,
                          title: 'Active Squad',
                          value: '$approvedCount Active',
                          percent: healthyPct,
                          accentBlue: true,
                          onTap: () => setState(() => _selectedIndex = _isAdmin ? 2 : 3),
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _buildNerveCard(
                          icon: Icons.person_add,
                          change: '-$pendingCount',
                          changePositive: false,
                          title: 'Live Recruiting',
                          value: '$pendingCount Leads',
                          percent: totalUsers > 0 ? ((pendingCount / totalUsers) * 100).round() : 0,
                          accentBlue: false,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * scale),
                  _buildFinancialCard(scale, onTap: () {}),
                  SizedBox(height: 24 * scale),
                  _buildSectionHeader('STRATEGIC FEED', null, null),
                  SizedBox(height: 12 * scale),
                  _buildFeedCard(
                    title: 'Account requests',
                    body: pendingCount > 0
                        ? '$pendingCount account request(s) waiting for approval.'
                        : 'No pending account requests.',
                    time: 'Now',
                    icon: Icons.pending_actions,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _buildFeedCard(
                    title: 'User activity',
                    body: 'Total registered users: $totalUsers.',
                    time: 'Today',
                    icon: Icons.people_outline,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedHubAppBar(double scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(16 * scale, MediaQuery.of(context).padding.top + 8, 16 * scale, 16 * scale),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: AppTheme.strokeDark, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22 * scale,
            backgroundColor: AppTheme.blueCiel.withOpacity(0.3),
            child: Text(
              'OD',
              style: TextStyle(
                color: AppTheme.blueFonce,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Odin ERP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.blueFonce,
                ),
              ),
              Text(
                'UNIFIED HUB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blueCiel,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          _iconCircle(Icons.search, scale),
          SizedBox(width: 8 * scale),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _iconCircle(Icons.notifications_none, scale),
              if (_pendingUsers.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconCircle(IconData icon, double scale) {
    return Container(
      width: 44 * scale,
      height: 44 * scale,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.blueFonce, size: 22 * scale),
    );
  }

  Widget _buildQuickAccessRow(double scale) {
    final items = <_QuickAccessItem>[
      _QuickAccessItem('Squad', Icons.sports_soccer, 3),
      _QuickAccessItem('Scouting', Icons.search, 1),
      _QuickAccessItem('Finance', Icons.account_balance, null),
      _QuickAccessItem('Medical', Icons.medical_services, null),
      _QuickAccessItem('Data', Icons.storage, null),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16 * scale),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          children: [
            for (final e in items)
              Padding(
                padding: EdgeInsets.only(right: 12 * scale),
                child: InkWell(
                  onTap: () {
                    if (e.index != null) setState(() => _selectedIndex = e.index!);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 72 * scale,
                    padding: EdgeInsets.symmetric(vertical: 14 * scale),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.strokeDark),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(e.icon, color: AppTheme.blueCiel, size: 28 * scale),
                        SizedBox(height: 6 * scale),
                        Text(
                          e.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.blueFonce,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionLabel, VoidCallback? onAction) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkGrey,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.blueCiel,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.strokeDark),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: AppTheme.blueCiel, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNerveCard({
    required IconData icon,
    required String change,
    required bool changePositive,
    required String title,
    required String value,
    required int percent,
    required bool accentBlue,
    VoidCallback? onTap,
  }) {
    final accent = accentBlue ? AppTheme.blueCiel : AppTheme.accentOrange;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: accent, width: 4),
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: changePositive ? AppTheme.accentGreen : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.darkGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.blueFonce,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 6,
              backgroundColor: AppTheme.strokeDark,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(double scale, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20 * scale),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.strokeDark),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '42.5M DT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.blueFonce,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Optimal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remaining Transfer Window Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.bar_chart, color: AppTheme.blueCiel, size: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.strokeDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.blueCiel.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.blueCiel, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkGrey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.blueCiel.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppTheme.blueFonce,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.blueFonce,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUsersView() {
    return Container(
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pending_actions,
                  color: AppTheme.blueFonce,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pending Approval',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blueFonce,
                    ),
                  ),
                ),
                if (_pendingUsers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.blueCiel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingUsers.length} requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadPendingUsers,
                  color: AppTheme.blueFonce,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingPending
                ? const Center(child: CircularProgressIndicator())
                : _pendingUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: AppTheme.blueCiel.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending users',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.darkGrey.withOpacity(0.7),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAllUsersView() {
    return Container(
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppTheme.blueFonce,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All Users',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blueFonce,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadAllUsers,
                      color: AppTheme.blueFonce,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRoleFilter ?? 'All',
                        decoration: _filterDecoration(
                          label: 'Filter by Role',
                          icon: Icons.filter_list,
                        ),
                        dropdownColor: AppTheme.white,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.blueFonce,
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.blueFonce,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPositionFilter ?? 'All',
                        decoration: _filterDecoration(
                          label: 'Filter by Position',
                          icon: Icons.sports_soccer,
                        ),
                        dropdownColor: AppTheme.white,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.blueFonce,
                        ),
                        items: _positions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(
                              position,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.blueFonce,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPositionFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingAll
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: AppTheme.blueCiel.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.darkGrey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(
                              Map<String, dynamic>.from(_filteredUsers[index]),
                              showActions: false,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool showActions = false}) {
    final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final email = user['email'] ?? '';
    final role = user['role'] ?? '';
    final roleCode = RoleMapper.normalize(role);
    final roleLabel = RoleMapper.toLabel(roleCode);
    final position = user['position'] ?? '';
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
                          color: AppTheme.blueFonce,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(roleCode).withOpacity(0.2),
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
                    if (position.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.blueCiel.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          position,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.blueFonce,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip('Email Verified', isEmailVerified, AppTheme.blueCiel),
                const SizedBox(width: 8),
                _buildStatusChip('Approved', isApproved, AppTheme.blueFonce),
                const SizedBox(width: 8),
                _buildStatusChip('Active', isActive, AppTheme.blueCiel),
              ],
            ),
            if (showActions && !isApproved) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _rejectUser(user['id'], fullName),
                    icon: Icon(Icons.close, size: 18),
                    label: Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.blueFonce,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveUser(user['id'], fullName),
                    icon: Icon(Icons.check, size: 18),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blueFonce,
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
        color: isActive ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
        return AppTheme.blueFonce;
      case 'STAFF_TECHNIQUE':
        return AppTheme.blueCiel;
      case 'SCOUT':
        return AppTheme.blueCiel;
      case 'FINANCIER':
        return AppTheme.blueFonce;
      case 'JOUEUR':
        return AppTheme.blueCiel;
      default:
        return Colors.grey;
    }
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final isHub = _selectedIndex == 0;
    return AppBar(
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.blueFonce,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        tooltip: 'Menu',
      ),
      title: isHub
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Odin ERP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.blueFonce,
                  ),
                ),
                Text(
                  'UNIFIED HUB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.blueCiel,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          : Text(
              'Admin Dashboard',
              style: TextStyle(
                color: AppTheme.blueFonce,
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
          tooltip: 'Search',
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            if (_pendingUsers.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminDrawer() {
    final isDark = ThemeController.isDark(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.blueFonce.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(color: AppTheme.strokeDark),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ODIN Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.blueFonce,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Icon(Icons.settings, color: AppTheme.blueFonce),
                    title: Text(
                      'Account & Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.blueFonce,
                    ),
                    title: Text(
                      isDark ? 'Dark mode (On)' : 'Light mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) {
                        ThemeController.toggle();
                        setState(() {});
                      },
                      activeColor: AppTheme.blueCiel,
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade700),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final scale = _scale(context);
    final showAdminItems = _isAdmin;
    final showManagerItems = _isManager;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.strokeDark, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 12 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showAdminItems)
                _navItem(
                  index: 1,
                  icon: Icons.pending_actions,
                  label: 'Pending',
                )
              else
                SizedBox(width: 64 * scale),
              if (showAdminItems)
                _navItem(
                  index: 2,
                  icon: Icons.people_outline,
                  label: 'Users',
                )
              else
                SizedBox(width: 64 * scale),
              _centerNavItem(),
              if (showManagerItems)
                _navItem(
                  index: 3,
                  icon: Icons.sports_soccer,
                  label: 'Players',
                )
              else
                SizedBox(width: 64 * scale),
              if (showManagerItems)
                _navItem(
                  index: 4,
                  icon: Icons.sports,
                  label: 'Coaches',
                )
              else
                SizedBox(width: 64 * scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    final scale = _scale(context);
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.darkGrey.withOpacity(0.6);
    return GestureDetector(
      onTap: enabled
          ? () {
              setState(() {
                _selectedIndex = index;
              });
            }
          : null,
      child: SizedBox(
        width: 64 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : AppTheme.darkGrey, size: 22 * scale),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: enabled ? color : AppTheme.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerNavItem() {
    final scale = _scale(context);
    final isSelected = _selectedIndex == 0;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.blueFonce.withOpacity(0.7);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * scale,
            height: 56 * scale,
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.blueCiel.withOpacity(0.6), width: 1.5 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Icon(
              Icons.dashboard,
              color: color,
              size: 26 * scale,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: AppTheme.darkGrey.withOpacity(0.9),
      ),
      prefixIcon: Icon(icon, color: AppTheme.blueCiel, size: 18),
      filled: true,
      fillColor: AppTheme.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.strokeDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.strokeDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.blueCiel, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobileLayout(context);
    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.lightGrey,
        appBar: _buildMobileAppBar(),
        drawer: _buildAdminDrawer(),
        body: _buildDashboardContent(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildDashboardContent(),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final int? index;
  _QuickAccessItem(this.label, this.icon, this.index);
}
