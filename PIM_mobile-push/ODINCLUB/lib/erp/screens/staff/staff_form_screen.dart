import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/staff_provider.dart';
import '../../providers/teams_provider.dart';

class StaffFormScreen extends StatefulWidget {
  final String? staffId;
  const StaffFormScreen({super.key, this.staffId});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _specialization = TextEditingController();
  final _licenseNumber = TextEditingController();

  String _role = 'Entraîneur principal';
  String? _teamId;
  String _status = 'active';
  DateTime? _contractEnd;
  bool _isEdit = false;
  String? _editId;
  bool _saving = false;

  final _roles = [
    'Entraîneur principal',
    'Entraîneur adjoint',
    'Entraîneur des gardiens',
    'Préparateur physique',
    'Médecin',
    'Kinésithérapeute',
    'Nutritionniste',
    'Analyste vidéo',
    'Recruteur',
    'Manager',
    'Directeur Sportif',
    'Autre',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.staffId;
    if (id != null && !_isEdit) {
      _isEdit = true;
      _editId = id;
      final staff = Provider.of<StaffProvider>(context, listen: false).selectedStaff;
      if (staff != null) {
        _firstName.text = staff.firstName;
        _lastName.text = staff.lastName;
        _email.text = staff.email ?? '';
        _phone.text = staff.phone ?? '';
        _role = staff.role;
        _teamId = staff.teamId;
        _specialization.text = staff.specialization ?? '';
        _licenseNumber.text = staff.licenseNumber ?? '';
        _contractEnd = staff.contractEndDate;
        _status = staff.status;
      }
    }
    Provider.of<TeamsProvider>(context, listen: false).fetchTeams();
  }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose();
    _email.dispose(); _phone.dispose();
    _specialization.dispose(); _licenseNumber.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEnd ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: OdinTheme.darkTheme.copyWith(
          colorScheme: const ColorScheme.dark(
            primary: OdinTheme.accentRed,
            surface: OdinTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _contractEnd = picked);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_specialization.text.trim().isNotEmpty) 'specialization': _specialization.text.trim(),
      if (_licenseNumber.text.trim().isNotEmpty) 'licenseNumber': _licenseNumber.text.trim(),
      'role': _role,
      if (_teamId != null) 'teamId': _teamId,
      if (_contractEnd != null) 'contractEndDate': _contractEnd!.toIso8601String().split('T').first,
      'status': _status,
    };

    final provider = Provider.of<StaffProvider>(context, listen: false);
    final success = _isEdit && _editId != null
        ? await provider.updateStaff(_editId!, data)
        : await provider.createStaff(data);

    setState(() => _saving = false);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  String _getDepartment(String role) {
    final r = role.toLowerCase();
    if (r.contains('médecin') || r.contains('kiné') || r.contains('nutrition') || r.contains('médical')) return 'Médical';
    if (r.contains('recruteur') || r.contains('scout')) return 'Recrutement';
    if (r.contains('analyste') || r.contains('vidéo')) return 'Analyse';
    return 'Technique';
  }

  @override
  Widget build(BuildContext context) {
    final teams = Provider.of<TeamsProvider>(context).teams;
    final dept = _getDepartment(_role);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: OdinTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: OdinTheme.accentRed, strokeWidth: 2)),
                )
              else
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, color: OdinTheme.accentRed, size: 18),
                  label: const Text('Sauvegarder', style: TextStyle(color: OdinTheme.accentRed, fontWeight: FontWeight.w600)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0F1E), OdinTheme.accentRed],
                    stops: [0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: OdinTheme.accentRed.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Icon(Icons.badge_rounded, color: OdinTheme.accentRed, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isEdit ? 'Modifier Membre' : 'Nouveau Staff',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Département $dept',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Form Body ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Section: Identité ─────────────────────────
                    _sectionHeader(Icons.person_rounded, 'IDENTITÉ'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_firstName, 'Prénom', required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_lastName, 'Nom', required: true)),
                    ]),
                    const SizedBox(height: 12),
                    _field(_email, 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _field(_phone, 'Téléphone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),

                    const SizedBox(height: 28),

                    // ── Section: Profil Professionnel ─────────────
                    _sectionHeader(Icons.work_rounded, 'PROFIL PROFESSIONNEL'),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      value: _role,
                      label: 'Rôle / Fonction',
                      icon: Icons.assignment_ind_rounded,
                      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                    const SizedBox(height: 12),
                    _field(_specialization, 'Spécialisation', icon: Icons.star_border_rounded, hint: 'Ex: Traumatologie, Cardio...'),
                    const SizedBox(height: 12),
                    _field(_licenseNumber, 'N° Licence / Diplôme', icon: Icons.verified_user_outlined),

                    const SizedBox(height: 28),

                    // ── Section: Affectation & Contrat ────────────
                    _sectionHeader(Icons.business_center_rounded, 'AFFECTATION & CONTRAT'),
                    const SizedBox(height: 12),
                    _dropdown<String?>(
                      value: _teamId,
                      label: 'Équipe (Optionnel)',
                      icon: Icons.groups_outlined,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Global / Toutes')),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (v) => setState(() => _teamId = v),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OdinTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OdinTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: OdinTheme.textTertiary, size: 18),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fin de contrat', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  _contractEnd == null ? 'Non défini' : '${_contractEnd!.day}/${_contractEnd!.month}/${_contractEnd!.year}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Submit ────────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [OdinTheme.accentRed, Color(0xFFC0392B)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: OdinTheme.accentRed.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          _isEdit ? 'ENREGISTRER LES MODIFICATIONS' : 'CRÉER LE MEMBRE',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: OdinTheme.accentRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: OdinTheme.accentRed, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: OdinTheme.cardBorder)),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {IconData? icon, TextInputType keyboardType = TextInputType.text, bool required = false, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: OdinTheme.textPrimary),
      validator: required ? (v) => v == null || v.isEmpty ? '$label requis' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: OdinTheme.textTertiary, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: OdinTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OdinTheme.accentRed, width: 1.5)),
      ),
    );
  }

  Widget _dropdown<T>({required T value, required String label, required IconData icon, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: OdinTheme.surfaceLight,
      style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: OdinTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OdinTheme.accentRed, width: 1.5)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
