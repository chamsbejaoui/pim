import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';
import '../../models/ai_player.dart';
import '../../services/ai_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';

/// Form screen with stat sliders to add a new player.
class AiCreatePlayerScreen extends StatefulWidget {
  const AiCreatePlayerScreen({super.key});

  @override
  State<AiCreatePlayerScreen> createState() =>
      _AiCreatePlayerScreenState();
}

class _AiCreatePlayerScreenState extends State<AiCreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '22');
  final _positionCtrl = TextEditingController(text: 'Midfielder');
  final _clubCtrl = TextEditingController();

  double _speed = 25.0;
  double _endurance = 70.0;
  double _distance = 9.0;
  double _dribbles = 8.0;
  double _shots = 5.0;
  double _injuries = 1.0;
  double _heartRate = 72.0;

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _positionCtrl.dispose();
    _clubCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final playerData = {
        'name': _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text) ?? 22,
        'position': _positionCtrl.text.trim(),
        'club': _clubCtrl.text.trim().isEmpty
            ? null
            : _clubCtrl.text.trim(),
        'speed': _speed,
        'endurance': _endurance,
        'distance': _distance,
        'dribbles': _dribbles.round(),
        'shots': _shots.round(),
        'injuries': _injuries.round(),
        'heart_rate': _heartRate.round(),
      };

      await AiApiService.createPlayerFromMap(playerData);
      if (mounted) {
        await context.read<CampaignProvider>().loadPlayers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_nameCtrl.text} added successfully!'),
          backgroundColor: AiColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AiColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AiColors.backgroundDark,
        title: const Text('Add Player',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add),
                label: Text(_saving ? 'Saving...' : 'Add Player'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AiColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.person, color: AiColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Player Info',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.primary)),
          ]),
          const SizedBox(height: 16),
          _buildTextField(_nameCtrl, 'Name', Icons.badge,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildTextField(
                    _ageCtrl, 'Age', Icons.cake,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTextField(
                    _positionCtrl, 'Position', Icons.sports_soccer)),
          ]),
          const SizedBox(height: 12),
          _buildTextField(
              _clubCtrl, 'Club (optional)', Icons.shield),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AiColors.textSecondary),
        prefixIcon:
            Icon(icon, color: AiColors.primary.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AiColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AiColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AiColors.primary),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart, color: AiColors.info, size: 20),
            SizedBox(width: 8),
            Text('Performance Stats',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.info)),
          ]),
          const SizedBox(height: 16),
          _statSlider('Speed (km/h)', _speed, 10, 40,
              (v) => setState(() => _speed = v), Icons.speed),
          _statSlider('Endurance', _endurance, 20, 100,
              (v) => setState(() => _endurance = v), Icons.timer),
          _statSlider('Distance (km)', _distance, 2, 15,
              (v) => setState(() => _distance = v), Icons.straighten),
          _statSlider('Dribbles', _dribbles, 0, 20,
              (v) => setState(() => _dribbles = v),
              Icons.sports_handball),
          _statSlider('Shots on Target', _shots, 0, 15,
              (v) => setState(() => _shots = v),
              Icons.gps_fixed),
          _statSlider('Injuries', _injuries, 0, 10,
              (v) => setState(() => _injuries = v),
              Icons.healing),
          _statSlider('Heart Rate (bpm)', _heartRate, 50, 200,
              (v) => setState(() => _heartRate = v),
              Icons.favorite),
        ],
      ),
    );
  }

  Widget _statSlider(String label, double value, double min,
      double max, ValueChanged<double> onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon,
                size: 14,
                color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AiColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AiColors.primary,
              inactiveTrackColor: AiColors.primary.withOpacity(0.1),
              thumbColor: AiColors.primary,
              overlayColor: AiColors.primary.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
