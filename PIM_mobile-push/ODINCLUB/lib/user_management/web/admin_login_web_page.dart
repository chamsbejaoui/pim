import 'package:flutter/material.dart';

class AdminLoginWebPage extends StatefulWidget {
  const AdminLoginWebPage({super.key, required this.onLogin, this.errorText});

  final Future<void> Function(String email, String password) onLogin;
  final String? errorText;

  @override
  State<AdminLoginWebPage> createState() => _AdminLoginWebPageState();
}

class _AdminLoginWebPageState extends State<AdminLoginWebPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'admin@odin.local');
  final _password = TextEditingController(text: 'ChangeMe123!');
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _loading = true);
    await widget.onLogin(_email.text.trim(), _password.text);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFF9FBFF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Admin Web Login',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('Validation des comptes clubs en attente'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Mot de passe invalide';
                          }
                          return null;
                        },
                      ),
                      if (widget.errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading ? 'Connexion...' : 'Se connecter'),
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
