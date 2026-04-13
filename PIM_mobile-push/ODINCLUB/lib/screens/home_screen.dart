import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/theme_toggle_button.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'account_settings_screen.dart';
import '../sports_performance/screens/calendar/calendar_screen.dart';
import '../sports_performance/screens/players/players_list_screen.dart';
import '../sports_performance/screens/test_types/test_types_list_screen.dart';
import '../sports_performance/screens/reports/all_events_reports_screen.dart';
import '../sports_performance/theme/sp_colors.dart';
import '../sports_performance/theme/sp_typography.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ai/ai_campaign_screen.dart';
import 'package:provider/provider.dart' as prov;
import '../providers/campaign_provider.dart';
import '../sports_performance/screens/exercises/library_screen.dart';
import '../utils/role_mapper.dart';
import '../../season_planning/screens/season_list_screen.dart';
import '../../tactics/screens/tactics_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _userEmail;
  String? _userRole;
  String? _userFirstName;
  String? _userLastName;

  int _selectedIndex = 2;

  double _scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = width / 390.0;
    return scale.clamp(0.85, 1.2);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Get user profile from API
      final result = await _apiService.getUserProfile();

      if (result['success'] && result['data'] != null) {
        final userData = result['data'];
        setState(() {
          _userEmail = userData['email'];
          _userRole = userData['role'];
          _userFirstName = userData['firstName'];
          _userLastName = userData['lastName'];
        });
      } else {
        // Fallback: try to decode token
        final token = await _apiService.getToken();
        if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64.normalize(payload);
              final decoded = utf8.decode(base64.decode(normalized));
              final Map<String, dynamic> payloadMap = jsonDecode(decoded);

              setState(() {
                _userEmail = payloadMap['email'];
                _userRole = payloadMap['role'];
              });
            }
          } catch (e) {
            // If decoding fails, just show placeholder
            setState(() {
              _userEmail = 'user@example.com';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _userEmail = 'user@example.com';
      });
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.removeToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _selectedIndex == 2 ? SPColors.backgroundPrimary : AppTheme.lightGrey,
      appBar: AppBar(
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
        title: Text(
          'Club Management',
          style: TextStyle(
            color: AppTheme.blueFonce,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: EdgeInsets.only(right: 16 * scale),
            child: CircleAvatar(
              radius: 18 * scale,
              backgroundColor: AppTheme.blueCiel.withOpacity(0.3),
              child: Text(
                _initials(),
                style: TextStyle(
                  color: AppTheme.blueFonce,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, scale),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer(BuildContext context, double scale) {
    final isDark = ThemeController.isDark(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20 * scale, 24 * scale, 20 * scale, 16 * scale),
              decoration: BoxDecoration(
                color: AppTheme.blueFonce.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.strokeDark,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32 * scale,
                    backgroundColor: AppTheme.blueCiel.withOpacity(0.3),
                    child: Text(
                      _initials(),
                      style: TextStyle(
                        color: AppTheme.blueFonce,
                        fontWeight: FontWeight.bold,
                        fontSize: 22 * scale,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    '${_userFirstName ?? ''} ${_userLastName ?? ''}'.trim().isEmpty
                        ? 'User'
                        : '${_userFirstName ?? ''} ${_userLastName ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.blueFonce,
                    ),
                  ),
                  if (_userEmail != null) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      _userEmail!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                  if (_userRole != null) ...[
                    SizedBox(height: 6 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: AppTheme.blueCiel.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        RoleMapper.toLabel(_userRole),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blueFonce,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8 * scale),
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
                    leading: Icon(Icons.analytics_outlined, color: AppTheme.blueFonce),
                    title: Text(
                      'Metric Management',
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
                          builder: (_) => const TestTypesListScreen(),
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
                  if (RoleMapper.isAdmin(_userRole))
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: AppTheme.blueFonce),
                      title: Text(
                        'Admin Panel',
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
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.psychology, color: AppTheme.blueFonce),
                    title: Text(
                      'AI Scouting',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    subtitle: Text(
                      'AI-powered player recruitment',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => prov.ChangeNotifierProvider.value(
                            value: prov.Provider.of<CampaignProvider>(context, listen: false),
                            child: const AiCampaignScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fitness_center, color: AppTheme.blueFonce),
                    title: Text(
                      'Exercise Library',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    subtitle: Text(
                      'Smart drills & AI Generator',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Import is needed but I'll add it or it will be auto-imported by IDE
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LibraryScreen(),
                        ),
                      );
                    },
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

  String _initials() {
    final first = _userFirstName?.trim();
    final last = _userLastName?.trim();
    if (first != null && first.isNotEmpty) {
      final firstChar = first[0].toUpperCase();
      final lastChar = (last != null && last.isNotEmpty) ? last[0].toUpperCase() : '';
      return '$firstChar$lastChar';
    }
    return 'OC';
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const PlayersListScreen();
      case 1:
        return const CalendarScreen(); // Sports Performance Calendar
      case 2:
        return _buildDashboardView();
      case 3:
        return const LibraryScreen();
      case 4:
        return const AllEventsReportsScreen();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final scale = _scale(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(20 * scale, 24 * scale, 20 * scale, 100 * scale),
      children: [
        _buildExecutiveHeader(scale),
        const SizedBox(height: 24),
        _buildSeasonPlanButton(scale),
        const SizedBox(height: 16),
        _buildTacticsButton(scale),
        const SizedBox(height: 32),
        _buildStatsGrid(scale),
        const SizedBox(height: 32),
        _buildPerformanceTrends(scale),
        const SizedBox(height: 32),
        _buildActiveEvents(scale),
      ],
    );
  }

  Widget _buildExecutiveHeader(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXECUTIVE VIEW',
              style: SPTypography.overline.copyWith(
                color: SPColors.primaryBlue,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Odin Dashboard',
              style: SPTypography.h2.copyWith(color: Colors.white),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 24 * scale,
            backgroundColor: AppTheme.blueCiel.withOpacity(0.1),
            child: Text(
              _initials(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonPlanButton(double scale) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeasonListScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SPColors.primaryBlue, SPColors.primaryBlueLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SPColors.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.date_range, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planification Saison',
                    style: SPTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérer les macro et micro cycles',
                    style: SPTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticsButton(double scale) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TacticsBoardScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade800, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyse Tactique & Adversaire',
                    style: SPTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Générer un XI de départ sur-mesure (IA)',
                    style: SPTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(double scale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'TOTAL EVENTS',
                value: '24',
                change: '+ 12%',
                changePositive: true,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                title: 'ACTIVE PLAYERS',
                value: '158',
                change: '+ 5%',
                changePositive: true,
                icon: Icons.group,
                iconColor: SPColors.primaryBlueLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'UNITS SOLD',
                value: '1.2k',
                change: '+ 8%',
                changePositive: true,
                icon: Icons.shopping_bag,
                iconColor: SPColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                title: 'REVENUE',
                value: '\$45k',
                change: '+ 15%',
                changePositive: true,
                icon: Icons.attach_money,
                iconColor: SPColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceTrends(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERFORMANCE TRENDS',
              style: SPTypography.overline.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SPColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5)),
              ),
              child: Text(
                'Live',
                style: SPTypography.caption.copyWith(
                  color: SPColors.primaryBlueLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220 * scale,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          decoration: BoxDecoration(
            color: SPColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
          ),
          child: _buildAreaChart(),
        ),
      ],
    );
  }

  Widget _buildAreaChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: SPColors.textTertiary, fontSize: 10);
                switch (value.toInt()) {
                  case 0: return const Text('JAN', style: style);
                  case 2: return const Text('FEB', style: style);
                  case 4: return const Text('MAR', style: style);
                  case 6: return const Text('APR', style: style);
                  case 8: return const Text('MAY', style: style);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 8, minY: 0, maxY: 6,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 1.5),
              FlSpot(2, 1.2),
              FlSpot(4, 2.8),
              FlSpot(6, 3.5),
              FlSpot(8, 5.2),
            ],
            isCurved: true,
            color: SPColors.primaryBlue,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: index == 4 ? Colors.white : SPColors.primaryBlue,
                strokeWidth: 2,
                strokeColor: SPColors.primaryBlue,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  SPColors.primaryBlue.withOpacity(0.3),
                  SPColors.primaryBlue.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEvents(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE EVENTS',
              style: SPTypography.overline.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'View All',
              style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEventCard('Regional Qualifiers', 'In Progress • Day 2', '42', Icons.emoji_events),
        const SizedBox(height: 12),
        _buildEventCard('Training Camp Alpha', 'Starting Soon • 14:00', '18', Icons.fitness_center),
        const SizedBox(height: 12),
        _buildEventCard('Scouting Combine', 'Registering', '64', Icons.visibility),
      ],
    );
  }

  Widget _buildEventCard(String title, String subtitle, String players, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SPColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SPTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                players,
                style: SPTypography.h4.copyWith(color: Colors.white),
              ),
              Text(
                'PLAYERS',
                style: SPTypography.overline.copyWith(color: SPColors.textTertiary, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _statCard({
    required String title,
    required String value,
    required String change,
    required bool changePositive,
    required IconData icon,
    Color? iconColor,
  }) {
    final scale = _scale(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: SPTypography.overline.copyWith(
                  color: SPColors.textTertiary,
                  fontSize: 9,
                ),
              ),
              Icon(icon, color: iconColor ?? SPColors.primaryBlue, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: SPTypography.h1.copyWith(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(width: 8),
              if (change.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      changePositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: changePositive ? SPColors.success : SPColors.error,
                      size: 12,
                    ),
                    Text(
                      change,
                      style: SPTypography.caption.copyWith(
                        color: changePositive ? SPColors.success : SPColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign out'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.blueFonce,
        ),
      ),
    );
  }

  Widget _buildPlayersView() {
    return const PlayersListScreen();
  }

  Widget _buildStaffView() {
    return _simplePlaceholder(
      title: 'Staff',
      subtitle: 'Track coaches, scouts, and support staff.',
      icon: Icons.badge_outlined,
    );
  }

  Widget _buildFinanceView() {
    return _simplePlaceholder(
      title: 'Finance',
      subtitle: 'Monitor budgets, payroll, and transfers.',
      icon: Icons.account_balance_wallet_outlined,
    );
  }

  Widget _buildReportsView() {
    return _simplePlaceholder(
      title: 'Reports',
      subtitle: 'Review performance and operational reports.',
      icon: Icons.insert_chart_outlined,
    );
  }

  Widget _simplePlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final scale = _scale(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72 * scale,
              height: 72 * scale,
              decoration: BoxDecoration(
                color: AppTheme.blueCiel.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              child: Icon(icon, color: AppTheme.blueFonce, size: 36 * scale),
            ),
            SizedBox(height: 16 * scale),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blueFonce,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppTheme.darkGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final scale = _scale(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              _navItem(
                index: 0,
                icon: Icons.group_outlined,
                label: 'Players',
              ),
              _navItem(
                index: 1,
                icon: Icons.calendar_today_outlined,
                label: 'Suivi Match',
              ),
              _centerNavItem(),
              _navItem(
                index: 3,
                icon: Icons.fitness_center,
                label: 'Exercises',
              ),
              _navItem(
                index: 4,
                icon: Icons.insert_chart_outlined,
                label: 'Rapports Suivis',
              ),
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
  }) {
    final scale = _scale(context);
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.darkGrey.withOpacity(0.6);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 64 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22 * scale),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerNavItem() {
    final scale = _scale(context);
    final isSelected = _selectedIndex == 2;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.blueFonce.withOpacity(0.7);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2;
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
}
