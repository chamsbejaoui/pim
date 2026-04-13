import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as prov;
import 'admin_web/admin_web_shell.dart';
import 'admin_web/theme/admin_theme.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'providers/campaign_provider.dart';
import 'sports_performance/cognitive_lab/providers/cognitive_lab_provider.dart';
import 'utils/role_router.dart';
import 'user_management/models/user_management_models.dart';

void main() {
  if (kIsWeb) {
    runApp(const AdminWebApp());
    return;
  }
  runApp(
    ProviderScope(
      child: prov.MultiProvider(
        providers: [
          prov.ChangeNotifierProvider(create: (_) => CampaignProvider()),
          prov.ChangeNotifierProvider(create: (_) => CognitiveLabProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ODIN Club',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;
    AdminPalette.setDarkMode(isDark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ODIN Admin Web',
      themeMode: _themeMode,
      theme: buildAdminWebLightTheme(),
      darkTheme: buildAdminWebDarkTheme(),
      home: AdminWebShell(onToggleTheme: _toggleTheme),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _apiService = ApiService();
  bool _isLoading = true;
  SessionModel? _session;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _apiService.getToken();
    SessionModel? session;
    if (token != null) {
      session = _sessionFromToken(token);
    }
    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  SessionModel _sessionFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64.normalize(payload);
        final decoded = utf8.decode(base64.decode(normalized));
        final Map<String, dynamic> payloadMap = jsonDecode(decoded);
        return SessionModel(
          token: token,
          userId: (payloadMap['sub'] ?? '').toString(),
          role: (payloadMap['role'] ?? '').toString(),
          email: (payloadMap['email'] ?? '').toString(),
          status: (payloadMap['status'] ?? '').toString(),
          clubId: payloadMap['clubId']?.toString(),
          clubName: payloadMap['clubName']?.toString(),
          firstName: payloadMap['firstName']?.toString(),
          lastName: payloadMap['lastName']?.toString(),
          photoUrl: payloadMap['photoUrl']?.toString(),
        );
      }
    } catch (_) {}
    return SessionModel(
      token: token,
      userId: '',
      role: '',
      email: '',
      status: '',
      clubId: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final session = _session;
    if (session != null) {
      return buildRoleHome(session);
    }
    return const LoginScreen();
  }
}
