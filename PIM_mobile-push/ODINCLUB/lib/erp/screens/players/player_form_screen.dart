import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/players_provider.dart';
import '../../providers/teams_provider.dart';
import '../../providers/categories_provider.dart';

class PlayerFormScreen extends StatefulWidget {
  final String? playerId;
  const PlayerFormScreen({super.key, this.playerId});

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationality = TextEditingController();
  final _jerseyNumber = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String _position = 'Attaquant';
  String? _preferredFoot;
  String? _teamId;
  String? _categoryId;
  String _status = 'active';
  DateTime? _dateOfBirth;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  bool _isEdit = false;
  String? _editId;
  bool _saving = false;

  final _positions = ['Gardien', 'Défenseur', 'Milieu', 'Attaquant'];
  final _feet = ['Droit', 'Gauche', 'Les deux'];
  final _statuses = {
    'active': ('Actif', OdinTheme.accentGreen),
    'injured': ('Blessé', OdinTheme.accentRed),
    'suspended': ('Suspendu', OdinTheme.accentOrange),
    'inactive': ('Inactif', OdinTheme.textTertiary),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.playerId;
    if (id != null && !_isEdit) {
      _isEdit = true;
      _editId = id;
      final player = Provider.of<PlayersProvider>(context, listen: false).selectedPlayer;
      if (player != null) {
        _firstName.text = player.firstName;
        _lastName.text = player.lastName;
        _position = player.position;
        _preferredFoot = player.preferredFoot;
        _jerseyNumber.text = player.jerseyNumber?.toString() ?? '';
        _height.text = player.height?.toString() ?? '';
        _weight.text = player.weight?.toString() ?? '';
        _teamId = player.teamId;
        _categoryId = player.categoryId;
        _dateOfBirth = player.dateOfBirth;
      }
    }
    Provider.of<TeamsProvider>(context, listen: false).fetchTeams();
    Provider.of<CategoriesProvider>(context, listen: false).fetchCategories();
  }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose();
    _nationality.dispose(); _jerseyNumber.dispose();
    _height.dispose(); _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: field == 'dob' ? DateTime(2000) : now,
      firstDate: field == 'dob' ? DateTime(1970) : DateTime(2020),
      lastDate: field == 'contractEnd' ? DateTime(2035) : now,
      builder: (ctx, child) => Theme(
        data: OdinTheme.darkTheme.copyWith(
          colorScheme: const ColorScheme.dark(
            primary: OdinTheme.primaryBlue,
            surface: OdinTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (field == 'dob') {
        _dateOfBirth = picked;
      } else if (field == 'contractStart') {
        _contractStart = picked;
      } else if (field == 'contractEnd') {
        _contractEnd = picked;
      }
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de naissance'),
          backgroundColor: OdinTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      if (_nationality.text.trim().isNotEmpty) 'nationality': _nationality.text.trim(),
      'position': _position,
      if (_preferredFoot != null) 'preferredFoot': _preferredFoot,
      if (_jerseyNumber.text.trim().isNotEmpty) 'jerseyNumber': int.tryParse(_jerseyNumber.text.trim()),
      if (_height.text.trim().isNotEmpty) 'height': double.tryParse(_height.text.trim()),
      if (_weight.text.trim().isNotEmpty) 'weight': double.tryParse(_weight.text.trim()),
      if (_teamId != null) 'teamId': _teamId,
      if (_categoryId != null) 'categoryId': _categoryId,
      if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String(),
      if (_contractStart != null) 'contractStartDate': _contractStart!.toIso8601String(),
      if (_contractEnd != null) 'contractEndDate': _contractEnd!.toIso8601String(),
    };

    final provider = Provider.of<PlayersProvider>(context, listen: false);
    final success = _isEdit && _editId != null
        ? await provider.updatePlayer(_editId!, data)
        : await provider.createPlayer(data);

    if (!mounted) return;
    setState(() => _saving = false);
    
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: OdinTheme.accentRed,
        ),
      );
    }
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Sélectionner'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final teams = Provider.of<TeamsProvider>(context).teams;
    final categories = Provider.of<CategoriesProvider>(context).categories;

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
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: OdinTheme.primaryBlue, strokeWidth: 2),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, color: OdinTheme.primaryBlue, size: 18),
                  label: const Text('Sauvegarder', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w600)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0F1E), OdinTheme.primaryBlue],
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
                            border: Border.all(color: OdinTheme.primaryBlue.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Icon(Icons.sports_soccer_rounded, color: OdinTheme.primaryBlue, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isEdit ? 'Modifier le Joueur' : 'Nouveau Joueur',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEdit ? 'Mettez à jour la fiche' : 'Remplissez tous les champs essentiels',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                              ),
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
                    _field(_nationality, 'Nationalité', icon: Icons.flag_outlined),
                    const SizedBox(height: 12),
                    _dateTile('Date de naissance', _dateOfBirth, () => _pickDate('dob')),

                    const SizedBox(height: 28),

                    // ── Section: Profil Sportif ───────────────────
                    _sectionHeader(Icons.sports_rounded, 'PROFIL SPORTIF'),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      value: _position,
                      label: 'Position',
                      icon: Icons.manage_accounts_rounded,
                      items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _position = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_jerseyNumber, 'N° Maillot', icon: Icons.tag_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown<String?>(
                          value: _preferredFoot,
                          label: 'Pied',
                          icon: Icons.directions_walk_rounded,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('—')),
                            ..._feet.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                          ],
                          onChanged: (v) => setState(() => _preferredFoot = v),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_height, 'Taille (cm)', icon: Icons.height_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_weight, 'Poids (kg)', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                    ]),

                    const SizedBox(height: 28),

                    // ── Section: Contrat ──────────────────────────
                    _sectionHeader(Icons.gavel_rounded, 'CONTRAT'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _dateTile('Début', _contractStart, () => _pickDate('contractStart'))),
                      const SizedBox(width: 12),
                      Expanded(child: _dateTile('Fin', _contractEnd, () => _pickDate('contractEnd'))),
                    ]),

                    const SizedBox(height: 28),

                    // ── Section: Affectation ──────────────────────
                    _sectionHeader(Icons.groups_rounded, 'AFFECTATION'),
                    const SizedBox(height: 12),
                    _dropdown<String?>(
                      value: _teamId,
                      label: 'Équipe',
                      icon: Icons.shield_rounded,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Aucune équipe')),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (v) => setState(() => _teamId = v),
                    ),
                    const SizedBox(height: 12),
                    _dropdown<String?>(
                      value: _categoryId,
                      label: 'Catégorie',
                      icon: Icons.category_rounded,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Aucune catégorie')),
                        ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),

                    const SizedBox(height: 40),

                    // ── Submit ────────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: OdinTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: OdinTheme.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                          _isEdit ? 'SAUVEGARDER LES MODIFICATIONS' : 'CRÉER LE JOUEUR',
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
          decoration: BoxDecoration(
            color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: OdinTheme.primaryBlue, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: OdinTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: OdinTheme.cardBorder)),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: OdinTheme.textPrimary),
      validator: required ? (v) => v == null || v.isEmpty ? '$label requis' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: OdinTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OdinTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OdinTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OdinTheme.primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OdinTheme.primaryBlue, width: 1.5)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(date),
                  style: TextStyle(
                    color: date == null ? OdinTheme.textTertiary : OdinTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: OdinTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

}
extension on Color {
  // ignore: unused_element
  Color darker(double factor) => Color.fromARGB(
      (a * 255).round(), (r * 255 * factor).round(), (g * 255 * factor).round(), (b * 255 * factor).round());
}

extension _StatusData on MapEntry<String, (String, Color)> {
  String get label => value.$1;
  Color get color => value.$2;
}
