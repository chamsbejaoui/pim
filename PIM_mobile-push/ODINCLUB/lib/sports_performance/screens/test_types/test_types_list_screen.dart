import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/test_type.dart';
import '../../providers/test_types_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import 'create_test_type_screen.dart';

class TestTypesListScreen extends ConsumerStatefulWidget {
  const TestTypesListScreen({super.key});

  @override
  ConsumerState<TestTypesListScreen> createState() => _TestTypesListScreenState();
}

class _TestTypesListScreenState extends ConsumerState<TestTypesListScreen> {
  bool _showInactive = true;

  @override
  Widget build(BuildContext context) {
    final testTypesAsync = ref.watch(testTypesProvider(!_showInactive));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('EVALUATION METRICS', style: SPTypography.h4.copyWith(letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off, color: SPColors.textTertiary),
            onPressed: () => setState(() => _showInactive = !_showInactive),
            tooltip: _showInactive ? 'Hide inactive' : 'Show inactive',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoHero(),
          Expanded(
            child: testTypesAsync.when(
              data: (types) {
                if (types.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: types.length,
                  itemBuilder: (context, index) => _buildTypeCard(types[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTestTypeScreen()),
          );
        },
        backgroundColor: SPColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('NEW METRIC'),
      ),
    );
  }

  Widget _buildInfoHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: SPColors.primaryBlue, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Architecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Manage your scoring system and normalization metrics here.',
                  style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(TestType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: type.isActive ? SPColors.borderPrimary.withOpacity(0.3) : SPColors.error.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: type.isActive ? SPColors.primaryBlue.withOpacity(0.1) : SPColors.backgroundTertiary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            type.betterIsHigher ? Icons.trending_up : Icons.trending_down,
            color: type.isActive ? SPColors.primaryBlue : SPColors.textTertiary,
            size: 20,
          ),
        ),
        title: Text(
          type.name,
          style: SPTypography.bodyLarge.copyWith(color: type.isActive ? Colors.white : SPColors.textTertiary, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(type.unit, style: SPTypography.caption.copyWith(color: SPColors.primaryBlue, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('Range: ${type.minThreshold ?? '0'}-${type.maxThreshold ?? '100'}', style: TextStyle(color: SPColors.textTertiary, fontSize: 10)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: SPColors.textTertiary, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateTestTypeScreen(testTypeToEdit: type)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: SPColors.error, size: 20),
              onPressed: () => _showDeleteConfirmation(type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_outlined, size: 64, color: SPColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No metrics found', style: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TestType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        title: const Text('Delete Metric', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${type.name}"? Historical test results using this metric may be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(testTypeFormProvider.notifier).deleteTestType(type.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Metric deleted' : 'Error deleting metric'),
                    backgroundColor: success ? SPColors.success : SPColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SPColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
