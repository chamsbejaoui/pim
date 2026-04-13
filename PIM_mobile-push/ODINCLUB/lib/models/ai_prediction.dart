/// Parses the AI prediction response from the Python ML model.
class AiPrediction {
  final String decision;
  final double confidence;
  final String? clusterProfile;
  final Map<String, double>? shapExplanation;

  const AiPrediction({
    required this.decision,
    required this.confidence,
    this.clusterProfile,
    this.shapExplanation,
  });

  /// Parse the Python AI model response:
  /// {
  ///   "player_name": "...",
  ///   "recruitment": "Yes" | "No",
  ///   "confidence_score": 85.42,
  ///   "calibrated": true,
  ///   "cluster_profile": 0,
  ///   "cluster_label": "Elite",
  ///   "shap_explanation": {
  ///     "speed": { "shap_value": 0.12, "impact": "positive" },
  ///     ...
  ///   }
  /// }
  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    Map<String, double>? shapValues;
    if (json['shap_explanation'] != null) {
      shapValues = {};
      final rawShap = json['shap_explanation'] as Map<String, dynamic>;
      rawShap.forEach((key, value) {
        if (value is Map && value.containsKey('shap_value')) {
          shapValues![key] = (value['shap_value'] as num).toDouble();
        } else if (value is num) {
          shapValues![key] = value.toDouble();
        }
      });
    }

    return AiPrediction(
      decision: json['recruitment'] as String? ?? 'unknown',
      confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      clusterProfile: json['cluster_label'] as String? ??
          (json['cluster_profile'] != null
              ? 'Group ${json['cluster_profile']}'
              : null),
      shapExplanation: shapValues,
    );
  }

  bool get isRecruited => decision.toLowerCase() == 'yes';

  String get confidenceLabel {
    if (confidence >= 90) return 'Very High';
    if (confidence >= 70) return 'High';
    if (confidence >= 50) return 'Medium';
    return 'Low';
  }
}
