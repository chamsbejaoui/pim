import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/exercises_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../../../widgets/exercise_card.dart';
import 'generator_form.dart';
import 'stopwatch_performance_screen.dart';
import '../../providers/players_provider.dart';
import '../../../screens/players/player_details_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedCategory;
  bool _aiOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories => [
        'All',
        'Physical',
        'Technical',
        'Tactical',
        'Cognitive',
      ];

  bool _isGif(String? url) => url != null && (url.contains('giphy.com') || url.contains('.gif'));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _deleteExercise(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'exercice',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment supprimer "${exercise.name}" ?',
          style: const TextStyle(color: SPColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final service = ref.read(exercisesServiceProvider);
      await service.deleteExercise(exercise.id!);
      ref.invalidate(exercisesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${exercise.name}" supprimé'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── EDIT ──────────────────────────────────────────────────────────────────
  Future<void> _editExercise(Exercise exercise) async {
    final nameCtrl = TextEditingController(text: exercise.name);
    String selectedCategory = exercise.category.value;
    int selectedDifficulty = exercise.difficulty;
    String selectedIntensity = exercise.intensity.value;

    final categories = ['Physical', 'Technical', 'Tactical', 'Cognitive'];
    final intensities = ['Low', 'Medium', 'High'];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MODIFIER L\'EXERCICE',
                        style: SPTypography.label.copyWith(
                            color: SPColors.primaryBlue, letterSpacing: 2)),
                    IconButton(
                      icon: const Icon(Icons.close, color: SPColors.textTertiary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nom
                Text('Nom', style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    fillColor: SPColors.backgroundTertiary,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SPColors.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SPColors.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SPColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Catégorie
                Text('Catégorie', style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setModalState(() => selectedCategory = cat),
                      selectedColor: SPColors.primaryBlue,
                      backgroundColor: SPColors.backgroundTertiary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SPColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Difficulté
                Text('Difficulté : $selectedDifficulty/5',
                    style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontWeight: FontWeight.bold)),
                Slider(
                  value: selectedDifficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: SPColors.primaryBlue,
                  inactiveColor: SPColors.backgroundTertiary,
                  onChanged: (val) => setModalState(() => selectedDifficulty = val.toInt()),
                ),
                const SizedBox(height: 8),

                // Intensité
                Text('Intensité', style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: intensities.map((int) {
                    final isSelected = selectedIntensity == int;
                    final color = int == 'Low'
                        ? Colors.green
                        : (int == 'Medium' ? Colors.orange : Colors.red);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedIntensity = int),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.2) : SPColors.backgroundTertiary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? color : SPColors.borderPrimary),
                            ),
                            child: Text(
                              int,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? color : SPColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SPColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text('ENREGISTRER',
                        style: SPTypography.label.copyWith(
                            color: Colors.white, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;

    try {
      final service = ref.read(exercisesServiceProvider);
      await service.updateExercise(exercise.id!, {
        'name': nameCtrl.text.trim(),
        'category': selectedCategory,
        'difficulty': selectedDifficulty,
        'intensity': selectedIntensity,
      });
      ref.invalidate(exercisesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Exercice mis à jour ✓'),
          backgroundColor: SPColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'EXERCISE LIBRARY',
              style: SPTypography.overline.copyWith(
                color: SPColors.primaryBlue,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Odin Intelligent ERP',
              style: SPTypography.caption.copyWith(
                color: SPColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and AI Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un exercice...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildAiToggle(),
              ],
            ),
          ),

          // Categories Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = (_selectedCategory == null && category == 'All') ||
                      (_selectedCategory == category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category == 'All' ? null : category;
                        });
                      },
                      selectedColor: SPColors.badgeTechnical.withOpacity(0.3),
                      backgroundColor: SPColors.backgroundSecondary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SPColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? SPColors.badgeTechnical : SPColors.borderPrimary,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

          // Exercises List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises.where((e) {
                  final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || e.category.value == _selectedCategory;
                  final matchesAi = !_aiOnly || e.aiGenerated;
                  return matchesSearch && matchesCategory && matchesAi;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return _buildExerciseItem(exercise);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneratorForm()),
          );
        },
        backgroundColor: SPColors.badgeTechnical,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  // ─── Exercise Item with CRUD actions ──────────────────────────────────────
  Widget _buildExerciseItem(Exercise exercise) {
    return Dismissible(
      key: Key(exercise.id ?? exercise.name),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('SUPPRIMER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteExercise(exercise);
        return false; // on gère nous-mêmes via le dialog
      },
      child: Stack(
        children: [
          ExerciseCard(
            exercise: exercise,
            onTap: () => _showExerciseDetails(context, exercise),
            onAdd: () {},
          ),
          // Menu Modifier / Supprimer en haut à droite de la carte
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
              ),
              color: SPColors.backgroundSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, color: SPColors.primaryBlue, size: 18),
                      SizedBox(width: 10),
                      Text('Modifier', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 10),
                      Text('Supprimer', style: TextStyle(color: Colors.red.shade400, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') _editExercise(exercise);
                if (value == 'delete') _deleteExercise(exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _aiOnly ? SPColors.badgeTechnical.withOpacity(0.1) : SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _aiOnly ? SPColors.badgeTechnical : SPColors.borderPrimary,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _aiOnly = !_aiOnly),
        child: Row(
          children: [
             Icon(
              Icons.auto_awesome,
              size: 16,
              color: _aiOnly ? Colors.white : SPColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'AI ONLY',
              style: TextStyle(
                color: _aiOnly ? Colors.white : SPColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
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
          Icon(Icons.search_off, size: 64, color: SPColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Aucun exercice trouvé',
            style: SPTypography.bodyLarge.copyWith(color: SPColors.textSecondary),
          ),
          if (_aiOnly) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneratorForm()),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Générer avec l\'IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SPColors.badgeTechnical,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: SPColors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: SPColors.primaryBlue, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'VISUAL DRILL GUIDE',
                          style: SPTypography.label.copyWith(
                            color: SPColors.primaryBlue,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _isGif(exercise.imageUrl) ? 'MODE GIF ANIMÉ' : 'MODE SCHÉMA TACTIQUE',
                          style: SPTypography.caption.copyWith(
                            color: SPColors.textTertiary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Edit button in detail view
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: SPColors.primaryBlue),
                      onPressed: () {
                        Navigator.pop(context);
                        _editExercise(exercise);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Hero GIF Section with Overlays
                    if (exercise.imageUrl != null)
                      Stack(
                        children: [
                          Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: SPColors.primaryBlue.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.network(
                                exercise.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: SPColors.backgroundSecondary,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined, color: SPColors.primaryBlue.withOpacity(0.5), size: 40),
                                        const SizedBox(height: 8),
                                        Text('Image indisponible', style: SPTypography.caption),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isGif(exercise.imageUrl) ? Colors.red : SPColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isGif(exercise.imageUrl) ? Colors.red : SPColors.primaryBlue).withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isGif(exercise.imageUrl) ? 'LOOPING LIVE VIEW' : 'STRATÉGIE IA 2D/3D',
                                  style: SPTypography.caption.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 80),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SPColors.primaryBlue.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5)),
                              ),
                              child: const Icon(Icons.replay_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Text(
                      exercise.name,
                      style: SPTypography.h2.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSmallMetric(Icons.timer_outlined, '${exercise.duration.toInt()} Mins'),
                        const SizedBox(width: 16),
                        _buildSmallMetric(Icons.bolt, exercise.difficulty > 3 ? 'Pro Level' : 'Beginner'),
                        const SizedBox(width: 16),
                        _buildSmallMetric(Icons.straighten_rounded, '${exercise.technicalData?.equipment.length ?? 0} Items'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'DÉMARCHE DE L\'EXERCICE',
                      style: SPTypography.label.copyWith(
                        color: SPColors.primaryBlue,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...exercise.technicalData!.steps.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final isFirst = index == 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isFirst ? SPColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFirst ? SPColors.primaryBlue.withOpacity(0.3) : SPColors.borderPrimary.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isFirst ? SPColors.primaryBlue : SPColors.backgroundTertiary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      color: isFirst ? Colors.white : SPColors.textTertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ÉTAPE $index'.toUpperCase(),
                                      style: TextStyle(
                                        color: isFirst ? SPColors.primaryBlue : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.value,
                                      style: SPTypography.bodySmall.copyWith(
                                        color: isFirst ? Colors.white : SPColors.textSecondary,
                                        height: 1.5,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    Text(
                      'MATÉRIEL REQUIS',
                      style: SPTypography.caption.copyWith(
                        color: SPColors.textTertiary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (exercise.technicalData?.equipment ?? []).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: SPColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: SPColors.borderPrimary),
                          ),
                          child: Text(
                            item.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    _buildHistorySection(exercise),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: SPColors.backgroundPrimary,
                  border: Border(top: BorderSide(color: SPColors.primaryBlue.withOpacity(0.1))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Delete button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.red.shade700.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700.withOpacity(0.4)),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteExercise(exercise);
                        },
                        tooltip: 'Supprimer',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Start button
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: SPColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: SPColors.primaryBlue.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StopwatchPerformanceScreen(exercise: exercise),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'DÉMARRER',
                                  style: SPTypography.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildSmallMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: SPColors.primaryBlue, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHistorySection(Exercise exercise) {
    if (exercise.completedSessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SESSIONS RÉCENTES',
          style: SPTypography.label.copyWith(
            color: SPColors.primaryBlue,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        ...exercise.completedSessions.reversed.take(5).map((session) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: SPColors.backgroundTertiary,
                  child: Icon(Icons.person, size: 16, color: SPColors.textTertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joueur #${session.playerId.substring(session.playerId.length - 4)}',
                        style: SPTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${session.durationSeconds}s • ${session.lapsCount} tours • ${session.completedAt.day}/${session.completedAt.month}',
                        style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerDetailsScreen(playerId: session.playerId),
                      ),
                    );
                  },
                  child: Text(
                    'PROFIL',
                    style: TextStyle(color: SPColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
