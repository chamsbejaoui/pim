import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/api_service.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'player';
  String? _selectedClubId;
  List<dynamic> _clubs = [];
  bool _isLoadingClubs = true;

  final _roles = {
    'player': 'Joueur',
    'coach': 'Entraîneur',
    'medical_staff': 'Staff Médical',
    'technical_staff': 'Staff Technique',
    'scout': 'Recruteur',
    'admin': 'Administrateur',
    'director': 'Directeur',
    'admin_finance': 'Admin Finance',
  };

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final response = await ApiService().get('/clubs');
      if (mounted) {
        setState(() {
          _clubs = response is List ? response : [];
          if (_clubs.isNotEmpty) {
            _selectedClubId = _clubs.first['id'];
          }
          _isLoadingClubs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClubs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement clubs: $e'),
            backgroundColor: OdinTheme.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un club'),
          backgroundColor: OdinTheme.accentRed,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.register(
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      role: _selectedRole,
      clubId: _selectedClubId!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success']
              ? OdinTheme.accentGreen
              : OdinTheme.accentRed,
        ),
      );

      if (result['success']) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Inscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demande d\'adhésion',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Remplissez le formulaire ci-dessous pour soumettre votre candidature.',
                style: TextStyle(color: OdinTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              _buildField('Prénom', _firstNameController, Icons.person_rounded),
              const SizedBox(height: 16),
              _buildField('Nom', _lastNameController, Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _buildField('Email', _emailController, Icons.email_rounded,
                  inputType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Téléphone (optionnel)', _phoneController,
                  Icons.phone_rounded,
                  required: false, inputType: TextInputType.phone),
              const SizedBox(height: 16),

              // Club Dropdown
              const Text(
                'Club',
                style: TextStyle(
                  color: OdinTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingClubs
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: OdinTheme.primaryBlue),
                      ),
                    )
                  : Container(
                      decoration: OdinTheme.inputDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: _selectedClubId,
                        isExpanded: true,
                        dropdownColor: OdinTheme.surfaceLight,
                        underline: const SizedBox(),
                        style: const TextStyle(color: OdinTheme.textPrimary),
                        hint: const Text('Sélectionner un club',
                            style: TextStyle(color: OdinTheme.textTertiary)),
                        items: _clubs.map((club) {
                          return DropdownMenuItem<String>(
                            value: club['id'],
                            child: Text(club['name'] ?? 'Club Sans Nom'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedClubId = val);
                        },
                      ),
                    ),
              const SizedBox(height: 16),

              // Role dropdown
              const Text(
                'Rôle',
                style: TextStyle(
                  color: OdinTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: OdinTheme.inputDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  dropdownColor: OdinTheme.surfaceLight,
                  underline: const SizedBox(),
                  style: const TextStyle(color: OdinTheme.textPrimary),
                  items: _roles.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (auth.isLoading || _isLoadingClubs) ? null : _register,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SOUMETTRE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = true,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: OdinTheme.textPrimary),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
