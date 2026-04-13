import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/test_type.dart';
import '../../providers/test_types_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';

class CreateTestTypeScreen extends ConsumerStatefulWidget {
  final TestType? testTypeToEdit;

  const CreateTestTypeScreen({super.key, this.testTypeToEdit});

  @override
  ConsumerState<CreateTestTypeScreen> createState() => _CreateTestTypeScreenState();
}

class _CreateTestTypeScreenState extends ConsumerState<CreateTestTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minThresholdController = TextEditingController();
  final _maxThresholdController = TextEditingController();
  final _weightController = TextEditingController();

  // State
  TestCategory _selectedCategory = TestCategory.physical;
  bool _betterIsHigher = true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.testTypeToEdit != null) {
      final t = widget.testTypeToEdit!;
      _nameController.text = t.name;
      _unitController.text = t.unit;
      _descriptionController.text = t.description ?? '';
      _minThresholdController.text = t.minThreshold?.toString() ?? '';
      _maxThresholdController.text = t.maxThreshold?.toString() ?? '';
      _weightController.text = t.weight?.toString() ?? '1.0';
      _selectedCategory = t.category;
      _betterIsHigher = t.betterIsHigher;
      _isActive = t.isActive;
    } else {
      _weightController.text = '1.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _minThresholdController.dispose();
    _maxThresholdController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final testTypeModel = TestType(
        id: widget.testTypeToEdit?.id ?? '',
        name: _nameController.text,
        category: _selectedCategory,
        unit: _unitController.text,
        description: _descriptionController.text,
        scoringMethod: _betterIsHigher ? ScoringMethod.higherBetter : ScoringMethod.lowerBetter,
        minThreshold: double.tryParse(_minThresholdController.text),
        maxThreshold: double.tryParse(_maxThresholdController.text),
        betterIsHigher: _betterIsHigher,
        weight: double.tryParse(_weightController.text) ?? 1.0,
        isActive: _isActive,
      );

      TestType? result;
      if (widget.testTypeToEdit != null) {
        result = await ref.read(testTypeFormProvider.notifier).updateTestType(widget.testTypeToEdit!.id!, testTypeModel);
      } else {
        result = await ref.read(testTypeFormProvider.notifier).createTestType(testTypeModel);
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.testTypeToEdit != null ? 'Metric updated' : 'Metric created'),
            backgroundColor: SPColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.testTypeToEdit != null ? 'EDIT METRIC' : 'NEW METRIC', style: SPTypography.h4.copyWith(letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('BASIC INFORMATION'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'METRIC NAME',
                hint: 'e.g. 30m Sprint, Vertical Jump',
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _unitController,
                label: 'UNIT',
                hint: 'e.g. sec, cm, kg, bpm',
                validator: (v) => v!.isEmpty ? 'Unit required' : null,
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'DESCRIPTION (OPTIONAL)',
                hint: 'Détails sur la méthode de test...',
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('SCORING LOGIC'),
              const SizedBox(height: 16),
              _buildBetterIsHigherToggle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minThresholdController,
                      label: 'MIN VALUE (0 points)',
                      hint: '0.0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxThresholdController,
                      label: 'MAX VALUE (100 points)',
                      hint: '10.0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                label: 'IMPORTANCE WEIGHT (1.0 = Default)',
                hint: '1.0',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildActiveSwitch(),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SPColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.testTypeToEdit != null ? 'UPDATE METRIC' : 'CREATE METRIC',
                    style: SPTypography.h4.copyWith(color: Colors.white, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.3)),
            filled: true,
            fillColor: SPColors.backgroundSecondary.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBetterIsHigherToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERFORMANCE DIRECTION', style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDirectionOption(true, 'HIGHER IS BETTER', Icons.trending_up, 'e.g. Strength, Jump'),
            const SizedBox(width: 12),
            _buildDirectionOption(false, 'LOWER IS BETTER', Icons.trending_down, 'e.g. Sprint, Fatigue'),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionOption(bool value, String label, IconData icon, String subtitle) {
    final isSelected = _betterIsHigher == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _betterIsHigher = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? SPColors.primaryBlue.withOpacity(0.15) : SPColors.backgroundSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? SPColors.primaryBlue : SPColors.borderPrimary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? SPColors.primaryBlue : SPColors.textTertiary, size: 24),
              const SizedBox(height: 8),
              Text(label, style: SPTypography.caption.copyWith(color: isSelected ? Colors.white : SPColors.textTertiary, fontWeight: FontWeight.bold, fontSize: 10)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: SPColors.textTertiary.withOpacity(0.5), fontSize: 8), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORY', style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: SPColors.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TestCategory>(
              value: _selectedCategory,
              dropdownColor: SPColors.backgroundSecondary,
              icon: const Icon(Icons.keyboard_arrow_down, color: SPColors.primaryBlue),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (TestCategory? newValue) {
                if (newValue != null) setState(() => _selectedCategory = newValue);
              },
              items: TestCategory.values.map((TestCategory category) {
                return DropdownMenuItem<TestCategory>(
                  value: category,
                  child: Text(category.name.toUpperCase()),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.power_settings_new, color: SPColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Metric will appear in test selections', style: TextStyle(color: SPColors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: SPColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}
