import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class RoleConfig {
  final String id;
  final String label;
  final String title;
  final String emoji;
  final Color color;
  final String buttonText;
  final String defaultEmail;

  const RoleConfig({
    required this.id,
    required this.label,
    required this.title,
    required this.emoji,
    required this.color,
    required this.buttonText,
    required this.defaultEmail,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController(text: 'password123'); // Demo default
  bool _obscure = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<RoleConfig> _roles = [
    const RoleConfig(
      id: 'admin',
      label: 'Admin',
      title: 'ESPACE ADMINISTRATEUR',
      emoji: '⚙️',
      color: OdinTheme.primaryBlue,
      buttonText: '🔓 Se connecter',
      defaultEmail: 'admin@club.fr',
    ),
    const RoleConfig(
      id: 'coach',
      label: 'Coach',
      title: 'ESPACE ENTRAÎNEUR',
      emoji: '🎯',
      color: OdinTheme.primaryBlue,
      buttonText: '🎯 Accéder à mon espace',
      defaultEmail: 'coach@club.fr',
    ),
    const RoleConfig(
      id: 'player',
      label: 'Joueur',
      title: 'ESPACE JOUEUR',
      emoji: '⚽',
      color: OdinTheme.primaryBlue,
      buttonText: '⚽ Accéder à mon espace',
      defaultEmail: 'player@club.fr',
    ),
    const RoleConfig(
      id: 'medical',
      label: 'Médecin',
      title: 'ESPACE MÉDECIN',
      emoji: '🏥',
      color: OdinTheme.primaryBlue,
      buttonText: '🏥 Accéder au vault médical',
      defaultEmail: 'medecin@club.fr',
    ),
    const RoleConfig(
      id: 'accountant',
      label: 'Comptable',
      title: 'ESPACE FINANCE',
      emoji: '💰',
      color: OdinTheme.primaryBlue,
      buttonText: '💰 Accéder aux finances',
      defaultEmail: 'finance@club.fr',
    ),
    const RoleConfig(
      id: 'scout',
      label: 'Scout',
      title: 'RECRUTEMENT',
      emoji: '🔍',
      color: OdinTheme.primaryBlue,
      buttonText: '🔍 Espace recrutement',
      defaultEmail: 'scout@club.fr',
    ),
  ];

  late RoleConfig _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first; // Default Admin
    _emailController = TextEditingController(text: _selectedRole.defaultEmail);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onRoleSelected(RoleConfig role) {
    setState(() {
      _selectedRole = role;
      _emailController.text = role.defaultEmail;
    });
  }

  void _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (auth.isAuthenticated && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: OdinTheme.background, // Match electric blue and black requested
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: OdinTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: OdinTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Logo & Title ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ODIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ERP',
                            style: TextStyle(
                              color: OdinTheme.primaryBlue,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRole.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: OdinTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Fields ────────────────────────────────────
                      const Text(
                        'EMAIL',
                        style: TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: OdinTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: OdinTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: OdinTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _selectedRole.color, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'MOT DE PASSE',
                        style: TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: OdinTheme.textTertiary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: OdinTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: OdinTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: OdinTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _selectedRole.color, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Role Selection Grid ───────────────────────
                      const Text(
                        'VOTRE RÔLE',
                        style: TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          final isSelected = _selectedRole.id == role.id;
                          return GestureDetector(
                            onTap: () => _onRoleSelected(role),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? role.color.withValues(alpha: 0.1) : OdinTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? role.color : OdinTheme.cardBorder,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(role.emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(
                                    role.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : OdinTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ─── Error Message ─────────────────────────────
                      if (auth.error != null) ...[
                        Text(
                          auth.error!,
                          style: const TextStyle(color: OdinTheme.accentRed, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ─── Action Button ─────────────────────────────
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _selectedRole.buttonText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
