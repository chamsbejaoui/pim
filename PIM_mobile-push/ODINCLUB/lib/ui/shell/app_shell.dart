import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../user_management/api/user_management_api.dart';
import '../../utils/role_mapper.dart';
import '../../screens/login_screen.dart';
import '../navigation/menu_config.dart';
import '../navigation/app_routes.dart';
import '../theme/app_spacing.dart';
import '../../theme/theme_controller.dart';
import '../../user_management/models/user_management_models.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.session,
    required this.initialRoute,
    this.onLogout,
  });

  final SessionModel session;
  final String initialRoute;
  final VoidCallback? onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late String _currentRoute;
  late final List<String> _routeHistory;
  int _notificationCount = 0; // TODO: wire backend notification count endpoint.
  final UserManagementApi _userApi = UserManagementApi();
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _routeHistory = [_currentRoute];
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _navigate(String route) {
    final roleCode = RoleMapper.normalize(widget.session.role);
    final menuRoutes = MenuConfig.itemsForRole(
      widget.session.role,
    ).map((i) => i.route).toSet();
    final allowed = {
      ...menuRoutes,
      MenuConfig.defaultRouteForRole(widget.session.role),
      AppRoutes.messages,
      AppRoutes.notifications,
      AppRoutes.profile,
      if (roleCode == RoleMapper.admin) ...{
        AppRoutes.adminUsers,
        AppRoutes.auditLog,
      },
      AppRoutes.cognitiveDashboard,
      AppRoutes.squadCognitiveOverview,
      AppRoutes.seasonPlanning,
      AppRoutes.tactics,
      if (menuRoutes.contains(AppRoutes.analysis)) AppRoutes.uploadVideo,
    };

    if (!allowed.contains(route)) {
      final fallback = MenuConfig.defaultRouteForRole(widget.session.role);
      if (_currentRoute != fallback) {
        setState(() {
          _currentRoute = fallback;
          _routeHistory
            ..clear()
            ..add(fallback);
        });
      }
      return;
    }

    if (_currentRoute == route) return;
    setState(() {
      _currentRoute = route;
      _routeHistory.add(route);
      if (_routeHistory.length > 20) {
        _routeHistory.removeAt(0);
      }
    });
    Navigator.of(context).maybePop();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_routeHistory.length <= 1) return;
    setState(() {
      _routeHistory.removeLast();
      _currentRoute = _routeHistory.last;
    });
  }

  Future<void> _handleLogout() async {
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }
    final apiService = ApiService();
    await apiService.removeToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _startNotificationPolling() {
    _notificationTimer?.cancel();
    _refreshNotificationCount();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshNotificationCount();
    });
  }

  Future<void> _refreshNotificationCount() async {
    if (RoleMapper.normalize(widget.session.role) !=
        RoleMapper.clubResponsable) {
      if (_notificationCount != 0 && mounted) {
        setState(() => _notificationCount = 0);
      }
      return;
    }
    try {
      final pending = await _userApi.getPendingUsers(widget.session.token);
      if (!mounted) return;
      final count = pending.length;
      if (count != _notificationCount) {
        setState(() => _notificationCount = count);
      }
    } catch (_) {
      // keep previous count
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = MenuConfig.itemsForRole(widget.session.role);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final routeData = AppRoutes.resolve(_currentRoute, widget.session);
    final canGoBack =
        Navigator.of(context).canPop() || _routeHistory.length > 1;

    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: routeData.showAppBar
          ? AppBar(
              title: Text(routeData.title),
              leading: canGoBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _handleBack,
                    )
                  : null,
              actions: [
                IconButton(
                  tooltip: 'Messages',
                  onPressed: () => _navigate(AppRoutes.messages),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                _NotificationButton(
                  count: _notificationCount,
                  onPressed: () => _navigate(AppRoutes.notifications),
                ),
                const SizedBox(width: 4),
                _UserMenu(
                  session: widget.session,
                  onProfile: () => _navigate(AppRoutes.profile),
                  onLogout: _handleLogout,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      drawer: isWide ? null : _buildDrawer(items),
      body: AppShellScope(
        session: widget.session,
        navigate: _navigate,
        goBack: _handleBack,
        child: Row(
          children: [
            if (isWide) _buildRail(items),
            Expanded(
              child: Container(
                color: scaffoldColor,
                padding: routeData.usePadding
                    ? const EdgeInsets.all(AppSpacing.s24)
                    : EdgeInsets.zero,
                child: routeData.builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(List<MenuItemConfig> items) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(session: widget.session),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                children: [
                  for (final item in items)
                    _DrawerTile(
                      item: item,
                      selected: item.route == _currentRoute,
                      onTap: () => _navigate(item.route),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.onSurface),
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRail(List<MenuItemConfig> items) {
    final scheme = Theme.of(context).colorScheme;
    final selectedIndex = items.indexWhere(
      (item) => item.route == _currentRoute,
    );
    return NavigationRail(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        if (index >= 0 && index < items.length) {
          _navigate(items[index].route);
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: scheme.surface,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s16),
        child: _RailHeader(session: widget.session),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s16),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: _handleLogout,
              icon: Icon(
                Icons.logout,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.title),
          ),
      ],
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.session,
    required this.onProfile,
    required this.onLogout,
  });

  final SessionModel session;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = ThemeController.isDark(context);
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    final club = (session.clubName ?? '').trim();
    final initial =
        (name.isNotEmpty
                ? name[0]
                : session.email.isNotEmpty
                ? session.email[0]
                : 'U')
            .toUpperCase();

    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Account',
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case _UserMenuAction.profile:
            onProfile();
            break;
          case _UserMenuAction.toggleTheme:
            ThemeController.toggle();
            break;
          case _UserMenuAction.logout:
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Text(
            name.isEmpty ? 'User' : name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Text(
            club.isEmpty ? 'No club assigned' : club,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.toggleTheme,
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(isDark ? 'Light mode' : 'Dark mode'),
              const Spacer(),
              Icon(
                isDark
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                color: scheme.primary,
              ),
            ],
          ),
        ),
        const PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.profile,
          child: Text('Update Profile'),
        ),
        const PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.logout,
          child: Text('Logout'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

enum _UserMenuAction { profile, toggleTheme, logout }

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: count > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: TextStyle(
                      color: scheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary.withValues(alpha: 0.18),
            child: Text(
              (session.email.isNotEmpty ? session.email[0] : 'U').toUpperCase(),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            name.isEmpty ? session.email : name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(session.role, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MenuItemConfig item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: selected ? scheme.primary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withValues(alpha: 0.18),
          child: Text(
            (session.email.isNotEmpty ? session.email[0] : 'U').toUpperCase(),
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'ODIN',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
      ],
    );
  }
}

class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.session,
    required this.navigate,
    required this.goBack,
    required super.child,
  });

  final SessionModel session;
  final void Function(String route) navigate;
  final VoidCallback goBack;

  static AppShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(covariant AppShellScope oldWidget) {
    return oldWidget.session != session;
  }
}
