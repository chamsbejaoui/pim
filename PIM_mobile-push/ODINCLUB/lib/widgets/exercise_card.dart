import 'package:flutter/material.dart';
import '../sports_performance/models/exercise.dart';
import '../sports_performance/theme/sp_colors.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    this.onTap,
    this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: exercise.aiGenerated
              ? SPColors.primaryBlue.withOpacity(0.5)
              : SPColors.borderPrimary,
          width: exercise.aiGenerated ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with AI Badge and Image Placeholder
            Stack(
              children: [
                Container(
                  height: 150, // Increased height for better visibility
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SPColors.backgroundTertiary,
                        SPColors.backgroundSecondary.withOpacity(0.8),
                        SPColors.backgroundPrimary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                      ? Image.network(
                          exercise.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SPColors.primaryBlue.withOpacity(0.5),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
                if (exercise.aiGenerated)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SPColors.badgeTechnical,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: SPColors.badgeTechnical.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'AI POWERED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.duration < 1
                              ? '${(exercise.duration * 60).toInt()} sec'
                              : '${exercise.duration % 1 == 0 ? exercise.duration.toInt() : exercise.duration} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: SPColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onAdd != null)
                        IconButton(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_circle),
                          color: SPColors.primaryBlue,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Difficulty Stars
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < exercise.difficulty
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: SPColors.warning,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIntensityGauge(exercise.intensity),
                      _buildPositionIcons(exercise.targetPositions),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityGauge(IntensityLevel intensity) {
    return Row(
      children: [
        const Text(
          'Intensité',
          style: TextStyle(
            color: SPColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 6,
          width: 60,
          decoration: BoxDecoration(
            color: SPColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: intensity == IntensityLevel.low
                ? 0.3
                : (intensity == IntensityLevel.medium ? 0.6 : 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: intensity.color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: intensity.color.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionIcons(List<PitchPosition> positions) {
    return Row(
      children: positions.map((p) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SPColors.backgroundTertiary,
              shape: BoxShape.circle,
            ),
            child: Text(
              p.value,
              style: const TextStyle(
                color: SPColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(exercise.category),
            size: 48,
            color: SPColors.primaryBlue.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.category.label.toUpperCase(),
            style: TextStyle(
              color: SPColors.primaryBlue.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.physical:
        return Icons.fitness_center;
      case ExerciseCategory.technical:
        return Icons.sports_soccer;
      case ExerciseCategory.tactical:
        return Icons.map_outlined;
      case ExerciseCategory.cognitive:
        return Icons.psychology;
    }
  }
}
