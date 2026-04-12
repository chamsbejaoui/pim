import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/player.dart';
import '../../providers/players_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';

class CreatePlayerScreen extends ConsumerStatefulWidget {
  final Player? playerToEdit;
  
  const CreatePlayerScreen({super.key, this.playerToEdit});

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _nationalityController = TextEditingController();

  // State
  DateTime? _selectedDateOfBirth;
  String _selectedPosition = 'MID'; // Default
  String _selectedStrongFoot = 'Right'; // Default
  String? _selectedNationality; // Could be dropdown or text

  // Options
  final List<String> _positions = ['GK', 'DEF', 'MID', 'ATT'];
  final List<String> _strongFoots = ['Right', 'Left', 'Both'];
  // Simplified list for demo, ideally fetched or comprehensive
  final List<String> _nationalities = [
    'Tunisia', 'France', 'England', 'Spain', 'Germany', 'Italy', 'Brazil', 'Argentina', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.playerToEdit != null) {
      final p = widget.playerToEdit!;
      _firstNameController.text = p.firstName;
      _lastNameController.text = p.lastName;
      _heightController.text = p.height?.toString() ?? '';
      _weightController.text = p.weight?.toString() ?? '';
      _nationalityController.text = p.nationality ?? '';
      _selectedDateOfBirth = p.dateOfBirth;
      _selectedPosition = _positions.contains(p.position) 
          ? p.position 
          : (p.position.toLowerCase() == 'gool' ? 'GK' : _positions.first);
      _selectedStrongFoot = _strongFoots.contains(p.strongFoot) ? p.strongFoot : _strongFoots.first;
      _selectedNationality = _nationalities.contains(p.nationality) ? p.nationality : 'Other';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default ~18yo
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SPColors.primaryBlue,
              onPrimary: Colors.white,
              surface: SPColors.backgroundSecondary,
              onSurface: SPColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        title: Text(widget.playerToEdit != null ? 'Edit Player Profile' : 'New Player Profile', style: SPTypography.h4.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: SPTypography.button.copyWith(color: SPColors.textTertiary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoUpload(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('PERSONAL DETAILS', Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'e.g. Lionel',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'e.g. Messi',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Nationality',
                value: _selectedNationality,
                items: _nationalities,
                hint: 'Select country',
                onChanged: (val) => setState(() => _selectedNationality = val),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('TECHNICAL PROFILE', Icons.sports_soccer),
              const SizedBox(height: 16),
              
              _buildDropdown(
                label: 'Primary Position',
                value: _selectedPosition,
                items: _positions,
                hint: 'Select position',
                onChanged: (val) => setState(() => _selectedPosition = val!),
                isMain: true,
              ),
              const SizedBox(height: 16),
              
              _buildStrongFootSelector(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height',
                      hint: '180',
                      suffix: 'cm',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Weight',
                      hint: '75',
                      suffix: 'kg',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SPColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: SPColors.primaryBlue.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        widget.playerToEdit != null ? 'SAVE CHANGES' : 'CREATE PLAYER',
                        style: SPTypography.h4.copyWith(color: Colors.white, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: SPColors.borderPrimary,
                width: 2,
                style: BorderStyle.solid, // Dashed effect needs custom painter, simpler for now
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.person_add,
                    size: 40,
                    color: SPColors.textTertiary.withOpacity(0.5),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: SPColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Player Photo',
            style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SPColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: SPTypography.overline.copyWith(
            color: SPColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SPTypography.caption.copyWith(color: SPColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: SPTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SPTypography.bodyMedium.copyWith(color: SPColors.textTertiary.withOpacity(0.3)),
            suffixText: suffix,
            suffixStyle: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
            prefixIcon: icon != null ? Icon(icon, color: SPColors.textTertiary, size: 20) : null,
            filled: true,
            fillColor: SPColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SPColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SPColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SPColors.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SPColors.error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: SPTypography.caption.copyWith(color: SPColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SPColors.borderPrimary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateOfBirth == null
                        ? 'mm/dd/yyyy'
                        : DateFormat('MM/dd/yyyy').format(_selectedDateOfBirth!),
                    style: SPTypography.bodyMedium.copyWith(
                      color: _selectedDateOfBirth == null ? SPColors.textTertiary.withOpacity(0.3) : Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: SPColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    bool isMain = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SPTypography.caption.copyWith(color: SPColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: SPColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isMain ? SPColors.primaryBlue.withOpacity(0.5) : SPColors.borderPrimary),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: SPColors.textTertiary.withOpacity(0.3))),
              icon: const Icon(Icons.arrow_drop_down, color: SPColors.textTertiary),
              isExpanded: true,
              dropdownColor: SPColors.backgroundSecondary,
              style: SPTypography.bodyMedium.copyWith(color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrongFootSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strong Foot', style: SPTypography.caption.copyWith(color: SPColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: SPColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SPColors.borderPrimary),
          ),
          child: Row(
            children: _strongFoots.map((foot) {
              final isSelected = _selectedStrongFoot == foot;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStrongFoot = foot),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? SPColors.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      foot,
                      style: SPTypography.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : SPColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedDateOfBirth != null) {
      try {
        final playerModel = Player(
          id: widget.playerToEdit?.id ?? '',
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          dateOfBirth: _selectedDateOfBirth!,
          position: _selectedPosition,
          strongFoot: _selectedStrongFoot,
          nationality: _selectedNationality,
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
        );

        if (widget.playerToEdit != null) {
          await ref.read(playerFormProvider.notifier).updatePlayer(widget.playerToEdit!.id!, playerModel);
        } else {
          await ref.read(playerFormProvider.notifier).createPlayer(playerModel);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.playerToEdit != null ? 'Player updated successfully' : 'Player created successfully'),
              backgroundColor: SPColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: SPColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth'), backgroundColor: SPColors.warning),
      );
    }
  }
}
