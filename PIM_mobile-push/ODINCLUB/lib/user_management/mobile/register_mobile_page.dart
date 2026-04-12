import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';
import 'auth_theme_mobile.dart';

class RegisterMobilePage extends StatefulWidget {
  const RegisterMobilePage({
    super.key,
    required this.api,
    required this.onShowLogin,
  });

  final UserManagementApi api;
  final VoidCallback onShowLogin;

  @override
  State<RegisterMobilePage> createState() => _RegisterMobilePageState();
}

class _RegisterMobilePageState extends State<RegisterMobilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _responsableMode = true;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptTerms = false;

  List<ClubModel> _activeClubs = [];
  String? _error;
  String? _pickedPhotoDataUrl;
  Uint8List? _pickedPhotoBytes;

  final _clubName = TextEditingController();
  final _league = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _logo = TextEditingController();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String _role = 'JOUEUR';
  String? _clubId;
  String? _position;
  String? _jobTitle;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadActiveClubs();
  }

  @override
  void dispose() {
    _clubName.dispose();
    _league.dispose();
    _country.dispose();
    _city.dispose();
    _logo.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _loadActiveClubs() async {
    try {
      final clubs = await widget.api.getActiveClubs();
      if (mounted) {
        setState(() {
          _activeClubs = clubs;
          if (clubs.isNotEmpty) {
            _clubId = clubs.first.id;
          }
        });
      }
    } catch (_) {
      // Keep register open even when club list fails initially.
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 55,
        maxWidth: 720,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final mime = _detectMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      setState(() {
        _pickedPhotoBytes = bytes;
        _pickedPhotoDataUrl = dataUrl;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de selectionner la photo.');
    }
  }

  String _detectMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_pickedPhotoDataUrl == null) {
      setState(() => _error = 'Photo de profil requise.');
      return;
    }

    if (_password.text != _confirmPassword.text) {
      setState(
        () => _error = 'La confirmation du mot de passe ne correspond pas.',
      );
      return;
    }

    if (!_acceptTerms) {
      setState(
        () => _error = 'Please accept the Terms of Service and Privacy Policy.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_responsableMode) {
        await widget.api.registerResponsable({
          'clubName': _clubName.text.trim(),
          'league': _league.text.trim(),
          'country': _country.text.trim(),
          'city': _city.text.trim(),
          'logoUrl': _logo.text.trim(),
          'photoUrl': _pickedPhotoDataUrl,
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
        });
      } else {
        await widget.api.registerMember({
          'photoUrl': _pickedPhotoDataUrl,
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'role': _role,
          'clubId': _clubId,
          if (_role == 'JOUEUR') 'position': _position,
          if (_role == 'STAFF_TECHNIQUE' || _role == 'STAFF_MEDICAL')
            'jobTitle': _jobTitle,
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _responsableMode
                ? 'Inscription envoyee. Attendez la validation admin.'
                : 'Inscription envoyee. Attendez la validation du responsable club.',
          ),
        ),
      );

      widget.onShowLogin();
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

  InputDecoration _inputDecoration(BuildContext context, String hint) =>
      authInputDecoration(label: hint, hint: hint);

  DropdownButtonFormField<String> _dropdownField({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF0C1B31),
      style: const TextStyle(color: AuthPalette.text),
      iconEnabledColor: AuthPalette.muted,
      items: options
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AuthPalette.text),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: _inputDecoration(context, label),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AuthPalette.label,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.2,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: AuthPalette.text),
      cursorColor: AuthPalette.neonBlue,
      decoration: authInputDecoration(
        label: label,
        hint: hint ?? label,
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const positionOptions = ['GK', 'CB', 'CM', 'ST', 'RW', 'LW'];
    const techOptions = ['Coach', 'Head Coach', 'Analyst', 'Prep Physique'];
    const medOptions = ['Docteur', 'Kine', 'Physiotherapeute'];
    const roleOptions = [
      'JOUEUR',
      'STAFF_TECHNIQUE',
      'STAFF_MEDICAL',
      'FINANCIER',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
              children: [
                Row(
                  children: [
                    AuthCircleBackButton(onTap: widget.onShowLogin),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'ANALYTICS PRO',
                  style: TextStyle(
                    color: AuthPalette.neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AuthPalette.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join the ODIN analytics network and unlock AI-powered match insights for your club.',
                  style: TextStyle(
                    color: AuthPalette.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                AuthGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Account Type'),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, label: Text('Club Owner')),
                          ButtonSegment(
                            value: false,
                            label: Text('Team Member'),
                          ),
                        ],
                        selected: {_responsableMode},
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF173157);
                            }
                            return const Color(0xFF09172A);
                          }),
                          foregroundColor: WidgetStateProperty.all(
                            AuthPalette.text,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: AuthPalette.border),
                          ),
                        ),
                        onSelectionChanged: (set) =>
                            setState(() => _responsableMode = set.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AuthGlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF11284B),
                          border: Border.all(color: AuthPalette.borderStrong),
                          image: _pickedPhotoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_pickedPhotoBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _pickedPhotoBytes == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: AuthPalette.text,
                                size: 36,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Photo',
                              style: TextStyle(
                                color: AuthPalette.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Required for account verification',
                              style: TextStyle(
                                color: AuthPalette.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                OutlinedButton(
                                  onPressed: _pickPhoto,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AuthPalette.text,
                                    side: const BorderSide(
                                      color: AuthPalette.border,
                                    ),
                                    backgroundColor: const Color(0x22101E36),
                                  ),
                                  child: const Text('Choose image'),
                                ),
                                if (_pickedPhotoDataUrl != null)
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _pickedPhotoDataUrl = null;
                                      _pickedPhotoBytes = null;
                                    }),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: AuthPalette.neonBlue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_responsableMode) ...[
                  const SizedBox(height: 14),
                  AuthGlassCard(
                    child: Column(
                      children: [
                        _sectionTitle('Club Information'),
                        _textField(
                          controller: _clubName,
                          label: 'Club Name',
                          validator: (v) => _requiredField(v, 'Nom du club'),
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _league,
                          label: 'League',
                          validator: (v) => _requiredField(v, 'Ligue'),
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _country,
                          label: 'Country (optional)',
                        ),
                        const SizedBox(height: 12),
                        _textField(controller: _city, label: 'City (optional)'),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _logo,
                          label: 'Logo URL (optional)',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AuthGlassCard(
                  child: Column(
                    children: [
                      _sectionTitle('Personal Information'),
                      _textField(
                        controller: _firstName,
                        label: 'First Name',
                        validator: (v) => _requiredField(v, 'Nom'),
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _lastName,
                        label: 'Last Name',
                        validator: (v) => _requiredField(v, 'Prenom'),
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _phone,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        validator: (v) => _requiredField(v, 'Telephone'),
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _email,
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _password,
                        label: 'Password',
                        obscureText: _hidePassword,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AuthPalette.muted,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Minimum 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _confirmPassword,
                        label: 'Confirm Password',
                        obscureText: _hideConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _hideConfirmPassword = !_hideConfirmPassword,
                          ),
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AuthPalette.muted,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirmez le mot de passe';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (!_responsableMode) ...[
                  const SizedBox(height: 14),
                  AuthGlassCard(
                    child: Column(
                      children: [
                        _sectionTitle('Role & Team Assignment'),
                        _dropdownField(
                          context: context,
                          label: 'Role',
                          value: _role,
                          options: roleOptions,
                          onChanged: (value) => setState(() {
                            _role = value ?? _role;
                            _position = null;
                            _jobTitle = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey('club:$_clubId:${_activeClubs.length}'),
                          initialValue: _clubId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0C1B31),
                          iconEnabledColor: AuthPalette.muted,
                          style: const TextStyle(color: AuthPalette.text),
                          items: _activeClubs
                              .map(
                                (club) => DropdownMenuItem(
                                  value: club.id,
                                  child: Text(
                                    '${club.name} (${club.league})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AuthPalette.text,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _clubId = value),
                          validator: (v) => _requiredField(v, 'Club'),
                          decoration: _inputDecoration(context, 'Club'),
                        ),
                        if (_role == 'JOUEUR') ...[
                          const SizedBox(height: 12),
                          _dropdownField(
                            context: context,
                            label: 'Position',
                            value: _position,
                            options: positionOptions,
                            onChanged: (value) =>
                                setState(() => _position = value),
                            validator: (v) => _requiredField(v, 'Position'),
                          ),
                        ],
                        if (_role == 'STAFF_TECHNIQUE') ...[
                          const SizedBox(height: 12),
                          _dropdownField(
                            context: context,
                            label: 'Technical Role',
                            value: _jobTitle,
                            options: techOptions,
                            onChanged: (value) =>
                                setState(() => _jobTitle = value),
                            validator: (v) =>
                                _requiredField(v, 'Poste technique'),
                          ),
                        ],
                        if (_role == 'STAFF_MEDICAL') ...[
                          const SizedBox(height: 12),
                          _dropdownField(
                            context: context,
                            label: 'Medical Role',
                            value: _jobTitle,
                            options: medOptions,
                            onChanged: (value) =>
                                setState(() => _jobTitle = value),
                            validator: (v) =>
                                _requiredField(v, 'Poste medical'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AuthGlassCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptTerms = v ?? false),
                              shape: const CircleBorder(),
                              side: const BorderSide(
                                color: AuthPalette.borderStrong,
                              ),
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AuthPalette.electric;
                                }
                                return Colors.transparent;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: AuthPalette.muted),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AuthPalette.electric,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AuthPalette.electric,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: AuthPalette.danger),
                        ),
                      ],
                      const SizedBox(height: 14),
                      AuthPrimaryButton(
                        label: 'Sign Up',
                        loading: _loading,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AuthDividerLabel(label: 'OR REGISTER WITH'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AuthSocialButton(label: 'Google', onTap: () {}),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthSocialButton(label: 'Apple', onTap: () {}),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthSocialButton(label: 'Club SSO', onTap: () {}),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AuthLinkText(
                  prefix: 'Already have an account? ',
                  link: 'Log In',
                  onTap: widget.onShowLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName requis';
    }
    return null;
  }
}
