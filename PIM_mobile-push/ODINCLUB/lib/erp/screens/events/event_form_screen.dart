import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../providers/teams_provider.dart';

class EventFormScreen extends StatefulWidget {
  final String? eventId;
  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _opponent = TextEditingController();

  String _eventType = 'entrainement';
  String _visibility = 'club';
  String? _teamId;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 4));
  bool _saving = false;

  final _typeConfig = {
    'match': ('Match', Icons.sports_soccer_rounded, OdinTheme.accentOrange),
    'entrainement': ('Entraînement', Icons.fitness_center_rounded, OdinTheme.primaryBlue),
    'detection': ('Scouting', Icons.radar_rounded, OdinTheme.accentGreen),
    'reunion': ('Réunion', Icons.groups_rounded, OdinTheme.accentCyan),
    'test_physique': ('Test Physique', Icons.monitor_heart_rounded, OdinTheme.accentPurple),
    'autre': ('Autre', Icons.event_rounded, OdinTheme.textSecondary),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<TeamsProvider>(context, listen: false).fetchTeams();
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose();
    _location.dispose(); _opponent.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
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
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = dt;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(hours: 2));
      } else {
        _endDate = dt;
      }
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final data = <String, dynamic>{
        'eventType': _eventType,
        'title': _title.text.trim(),
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'allDay': false,
        'visibility': _visibility,
        if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
        if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
        if (_teamId != null) 'teamId': _teamId,
        if (_opponent.text.trim().isNotEmpty && _eventType == 'match') 'eventDetails': {'opponent': _opponent.text.trim()},
      };

      final provider = Provider.of<EventsProvider>(context, listen: false);
      final success = await provider.createEvent(data);

      if (!mounted) return;
      setState(() => _saving = false);
      
      if (success) {
        await provider.fetchCalendar(
          DateTime(_startDate.year, _startDate.month, 1),
          DateTime(_startDate.year, _startDate.month + 1, 0),
        );
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: OdinTheme.accentRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur interne du formulaire: $e'),
            backgroundColor: OdinTheme.accentRed,
          ),
        );
      }
    }
  }

  String _fmtDT(DateTime dt) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[dt.weekday - 1]} ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} à ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }

  Duration get _duration => _endDate.difference(_startDate);

  String get _durationLabel {
    final h = _duration.inHours;
    final m = _duration.inMinutes % 60;
    return h > 0 ? '${h}h${m > 0 ? '${m}min' : ''}' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final teams = Provider.of<TeamsProvider>(context).teams;
    final typeInfo = _typeConfig[_eventType]!;
    final Color accentColor = typeInfo.$3;

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
                  child: SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: OdinTheme.primaryBlue, strokeWidth: 2)),
                )
              else
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, color: OdinTheme.primaryBlue, size: 18),
                  label: const Text('Créer', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w700)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E293B), // Deep blue-gray
                      const Color(0xFF0F172A), // Dark navy
                      accentColor.withValues(alpha: 0.8), // Accent color at bottom
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Icon(typeInfo.$2, color: accentColor, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Nouvel Événement',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  key: ValueKey(_eventType),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    typeInfo.$1,
                                    style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

                    // ── Type selector (visual cards) ──────────────
                    _sectionHeader(Icons.style_rounded, 'TYPE D\'ÉVÉNEMENT'),
                    const SizedBox(height: 12),
                    _eventTypeGrid(),
                    const SizedBox(height: 28),

                    // ── Title / Info ──────────────────────────────
                    _sectionHeader(Icons.info_outline_rounded, 'INFORMATIONS'),
                    const SizedBox(height: 12),
                    _field(_title, 'Titre de l\'événement', icon: Icons.title_rounded, required: true),
                    const SizedBox(height: 12),
                    if (_eventType == 'match') ...[
                      _field(_opponent, 'Équipe adverse', icon: Icons.sports_soccer_rounded),
                      const SizedBox(height: 12),
                    ],
                    _field(_location, 'Lieu / Stade', icon: Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _field(_description, 'Description', icon: Icons.notes_rounded, maxLines: 3),

                    const SizedBox(height: 28),

                    // ── Date & Time ───────────────────────────────
                    _sectionHeader(Icons.schedule_rounded, 'DATE & HEURE'),
                    const SizedBox(height: 12),
                    _dateRow(),

                    const SizedBox(height: 28),

                    // ── Visibility & Team ─────────────────────────
                    _sectionHeader(Icons.settings_rounded, 'PARAMÈTRES'),
                    const SizedBox(height: 12),
                    _visibilitySelector(),
                    const SizedBox(height: 12),
                    _dropdown<String?>(
                      value: _teamId,
                      label: 'Équipe concernée',
                      icon: Icons.shield_rounded,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tout le club')),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (v) => setState(() => _teamId = v),
                    ),

                    const SizedBox(height: 40),

                    // ── Submit ────────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accentColor, OdinTheme.primaryBlue]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
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
                            : Icon(typeInfo.$2, color: Colors.white, size: 20),
                        label: Text(
                          'CRÉER L\'ÉVÉNEMENT',
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

  Widget _eventTypeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: _typeConfig.entries.map((entry) {
        final selected = _eventType == entry.key;
        final color = entry.value.$3;
        return GestureDetector(
          onTap: () => setState(() => _eventType = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.15) : OdinTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : OdinTheme.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.value.$2, color: selected ? color : OdinTheme.textTertiary, size: 22),
                const SizedBox(height: 6),
                Text(
                  entry.value.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? color : OdinTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDateTime(true),
                child: _dateTileWidget('Début', _startDate, OdinTheme.primaryBlue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDateTime(false),
                child: _dateTileWidget('Fin', _endDate, OdinTheme.accentCyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: OdinTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: OdinTheme.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timelapse_rounded, color: OdinTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Durée: $_durationLabel',
                style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTileWidget(String label, DateTime dt, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OdinTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(label == 'Début' ? Icons.play_arrow_rounded : Icons.stop_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtDT(dt),
            style: const TextStyle(color: OdinTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _visibilitySelector() {
    final options = {
      'club': ('Club entier', Icons.domain_rounded),
      'team': ('Équipe', Icons.shield_rounded),
      'staff': ('Staff', Icons.badge_rounded),
      'public': ('Public', Icons.public_rounded),
    };
    return Row(
      children: options.entries.map((e) {
        final selected = _visibility == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _visibility = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? OdinTheme.primaryBlue.withValues(alpha: 0.15) : OdinTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? OdinTheme.primaryBlue : OdinTheme.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(e.value.$2, color: selected ? OdinTheme.primaryBlue : OdinTheme.textTertiary, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    e.value.$1,
                    style: TextStyle(
                      color: selected ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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

  Widget _field(TextEditingController ctrl, String label,
      {IconData? icon, TextInputType? keyboardType, int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: OdinTheme.textPrimary),
      validator: required ? (v) => v == null || v.isEmpty ? '$label requis' : null : null,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: OdinTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: OdinTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OdinTheme.primaryBlue, width: 1.5)),
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
}
