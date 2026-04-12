import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';
import 'auth_theme_mobile.dart';

class LoginMobilePage extends StatefulWidget {
  const LoginMobilePage({
    super.key,
    required this.api,
    required this.onSession,
    required this.onShowRegister,
  });

  final UserManagementApi api;
  final void Function(SessionModel session) onSession;
  final VoidCallback onShowRegister;

  @override
  State<LoginMobilePage> createState() => _LoginMobilePageState();
}

class _LoginMobilePageState extends State<LoginMobilePage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    final email = prefs.getString('remembered_email') ?? '';
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email.isNotEmpty) {
        _email.text = email;
      }
    });
  }

  Future<void> _persistRememberedUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_email', email);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('remembered_email');
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await widget.api.login(
        _email.text.trim(),
        _password.text,
      );
      await _persistRememberedUser(_email.text.trim());
      widget.onSession(session);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForgotPasswordPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ForgotPasswordMobilePage(
          api: widget.api,
          initialEmail: _email.text.trim(),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF091A2E),
        content: Text(message, style: const TextStyle(color: AuthPalette.text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: AuthBrandHero(
                              title: 'ODIN',
                            ),
                          ),
                          const SizedBox(height: 34),
                          AuthGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    color: AuthPalette.text,
                                  ),
                                  cursorColor: AuthPalette.neonBlue,
                                  decoration: authInputDecoration(
                                    label: 'Email Address',
                                    hint: 'name@example.com',
                                  ),
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty || !v.contains('@')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _hidePassword,
                                  style: const TextStyle(
                                    color: AuthPalette.text,
                                  ),
                                  cursorColor: AuthPalette.neonBlue,
                                  decoration: authInputDecoration(
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: AuthPalette.muted,
                                      ),
                                    ),
                                  ),
                                validator: (value) {
                                  if ((value ?? '').length < 6) {
                                    return 'Password is too short';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(
                                        () => _rememberMe = value ?? false,
                                      );
                                    },
                                    activeColor: AuthPalette.electric,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: AuthPalette.border.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(color: AuthPalette.muted),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                    onPressed: _openForgotPasswordPage,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AuthPalette.electric,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 0,
                                      ),
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AuthPalette.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                AuthPrimaryButton(
                                  label: 'Login ',
                                  loading: _loading,
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _login,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          AuthLinkText(
                            prefix: "Don't have an account? ",
                            link: 'Sign up',
                            onTap: widget.onShowRegister,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordMobilePage extends StatefulWidget {
  const _ForgotPasswordMobilePage({
    required this.api,
    required this.initialEmail,
  });

  final UserManagementApi api;
  final String initialEmail;

  @override
  State<_ForgotPasswordMobilePage> createState() =>
      _ForgotPasswordMobilePageState();
}

class _ForgotPasswordMobilePageState extends State<_ForgotPasswordMobilePage> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final TextEditingController _code = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  bool _codeRequested = false;
  bool _loading = false;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      if (!_codeRequested) {
        await widget.api.requestForgotPassword(email);
        if (!mounted) {
          return;
        }
        setState(() {
          _codeRequested = true;
          _success = 'Reset code sent. Check your inbox and enter the OTP.';
        });
        return;
      }

      if (_code.text.trim().length != 6) {
        throw Exception('OTP code must contain 6 digits');
      }
      if (_newPassword.text.length < 8) {
        throw Exception('New password must contain at least 8 characters');
      }
      if (_newPassword.text != _confirmPassword.text) {
        throw Exception('Password confirmation does not match');
      }

      await widget.api.resetForgotPassword(
        email: email,
        code: _code.text.trim(),
        newPassword: _newPassword.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. You can log in now.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
            children: [
              Row(
                children: [
                  AuthCircleBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ODIN ',
                      style: TextStyle(
                        color: AuthPalette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: AuthPalette.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _codeRequested
                    ? 'Enter the 6-digit OTP and choose a new password.'
                    : "Enter your email address and we'll send you instructions to reset your password.",
                style: const TextStyle(
                  color: AuthPalette.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              AuthGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(
                        color: AuthPalette.label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AuthPalette.text),
                      cursorColor: AuthPalette.neonBlue,
                      decoration: authInputDecoration(
                        label: 'Email Address',
                        hint: 'name@example.com',
                      ),
                    ),
                    if (_codeRequested) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AuthPalette.text),
                        cursorColor: AuthPalette.neonBlue,
                        decoration: authInputDecoration(
                          label: 'OTP Code',
                          hint: '6-digit code',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _newPassword,
                        obscureText: _hideNewPassword,
                        style: const TextStyle(color: AuthPalette.text),
                        cursorColor: AuthPalette.neonBlue,
                        decoration: authInputDecoration(
                          label: 'New Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _hideNewPassword = !_hideNewPassword,
                            ),
                            icon: Icon(
                              _hideNewPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AuthPalette.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPassword,
                        obscureText: _hideConfirmPassword,
                        style: const TextStyle(color: AuthPalette.text),
                        cursorColor: AuthPalette.neonBlue,
                        decoration: authInputDecoration(
                          label: 'Confirm Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _hideConfirmPassword = !_hideConfirmPassword,
                            ),
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AuthPalette.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AuthPalette.danger),
                      ),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _success!,
                        style: const TextStyle(color: AuthPalette.success),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AuthPrimaryButton(
                      label: _codeRequested
                          ? 'Reset Password'
                          : 'Send Reset Link',
                      loading: _loading,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AuthLinkText(
                prefix: 'Remember your password? ',
                link: 'Log in',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
