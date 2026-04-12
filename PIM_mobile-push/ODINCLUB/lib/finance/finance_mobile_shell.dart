import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'screens/ai_finance_screen.dart';
import 'screens/accounting_screen.dart';
import 'screens/audit_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/sponsors_screen.dart';
import 'screens/transfers_screen.dart';
import 'screens/treasury_screen.dart';
import 'theme/finance_theme.dart';
import 'widgets/finance_widgets.dart';
import '../player_value_ai/player_value_screen.dart';

class FinanceMobileShell extends StatefulWidget {
  const FinanceMobileShell({
    super.key,
    this.onLogout,
    this.onOpenMessages,
    this.avatarLabel = 'S',
    this.roleLabel = 'SERVER: OPERATIONAL',
    this.profileImage,
    this.embedded = false,
    this.initialIndex,
  });

  final VoidCallback? onLogout;
  final VoidCallback? onOpenMessages;
  final String avatarLabel;
  final String roleLabel;
  final String? profileImage;
  final bool embedded;
  final int? initialIndex;

  @override
  State<FinanceMobileShell> createState() => _FinanceMobileShellState();
}

class _FinanceMobileShellState extends State<FinanceMobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  static const _tabs = [
    ('Dashboard', Icons.grid_view_rounded),
    ('Revenus', Icons.trending_up_rounded),
    ('Accounting', Icons.receipt_long_rounded),
    ('Payroll', Icons.payments_rounded),
    ('Transfers', Icons.swap_horiz_rounded),
    ('Treasury', Icons.account_balance_rounded),
    ('Depenses', Icons.money_off_csred_rounded),
    ('Audit', Icons.verified_user_rounded),
    ('AI Finance', Icons.psychology_alt_rounded),
    ('Player Value AI', Icons.trending_up_rounded),
  ];

  final _screens = const [
    DashboardScreen(),
    SponsorsScreen(),
    AccountingScreen(),
    PayrollScreen(),
    TransfersScreen(),
    TreasuryScreen(),
    BudgetScreen(),
    AuditScreen(),
    AiFinanceScreen(),
    PlayerValueScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIndex ?? 0;
    if (initial >= 0 && initial < _screens.length) {
      _index = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    FinancePalette.setDarkMode(Theme.of(context).brightness == Brightness.dark);
    final tab = _tabs[_index];
    final profileImageProvider = _resolveProfileImage(widget.profileImage);
    final showAppBar = !widget.embedded;

    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: true,
      endDrawer: _FinanceSectionsDrawer(
        tabs: _tabs,
        selectedIndex: _index,
        onSelect: (index) {
          if (!mounted) {
            return;
          }
          setState(() => _index = index);
          Navigator.of(context).maybePop();
        },
      ),
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: const SizedBox.shrink(),
              leadingWidth: 54,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finance & Accounting',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${tab.$1.toUpperCase()}  •  ${widget.roleLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.3,
                      color: FinancePalette.blue,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  tooltip: 'Finance Sections',
                  icon: const Icon(Icons.view_sidebar_rounded),
                ),
                IconButton(
                  onPressed: widget.onOpenMessages,
                  tooltip: 'Messages',
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: FinancePalette.blue,
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? Text(widget.avatarLabel)
                        : null,
                  ),
                ),
              ],
            )
          : null,
      body: GradientShell(
        child: Column(
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finance & Accounting',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${tab.$1.toUpperCase()}  •  ${widget.roleLabel}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  color: FinancePalette.blue,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      tooltip: 'Finance Sections',
                      icon: const Icon(Icons.view_sidebar_rounded),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _screens[_index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceSectionsDrawer extends StatelessWidget {
  const _FinanceSectionsDrawer({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<(String, IconData)> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 312,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FinancePalette.card, FinancePalette.scaffold],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FinancePalette.soft),
              boxShadow: [
                BoxShadow(
                  color: FinancePalette.blue.withValues(alpha: 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: FinancePalette.soft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: FinancePalette.blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Finance Sections',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: FinancePalette.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: FinancePalette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Move between dashboard, transfers, treasury, audit and accounting views.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FinancePalette.muted,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final selected = index == selectedIndex;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onSelect(index),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? FinancePalette.blue.withValues(alpha: 0.16)
                                  : FinancePalette.card.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? FinancePalette.blue
                                    : FinancePalette.soft,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? FinancePalette.blue
                                        : FinancePalette.soft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    tab.$2,
                                    size: 18,
                                    color: selected
                                        ? Colors.white
                                        : FinancePalette.blue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tab.$1,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: FinancePalette.ink,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_rounded,
                                    color: FinancePalette.blue,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ImageProvider? _resolveProfileImage(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final raw = value.trim();
  if (raw.startsWith('data:image')) {
    try {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1) {
        return null;
      }
      final base64Data = raw.substring(commaIndex + 1);
      final bytes = base64Decode(base64Data);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  return NetworkImage(raw);
}
