enum AnalysisSource {
  api,
  cached,
  localML,
  simulated,
}

class FaceAnalysisResult {
  final double attractivenessScore;
  final String bestAngle;
  final String bestAngleDescription;
  final Map<String, double> facialFeatures;
  final String overallAnalysis;
  final String imageBase64;
  final AnalysisSource source;

  FaceAnalysisResult({
    required this.attractivenessScore,
    required this.bestAngle,
    required this.bestAngleDescription,
    required this.facialFeatures,
    required this.overallAnalysis,
    required this.imageBase64,
    this.source = AnalysisSource.api,
  });

  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FaceAnalysisResult(
      attractivenessScore: (json['attractivenessScore'] as num?)?.toDouble() ?? 0.0,
      bestAngle: json['bestAngle'] as String? ?? 'Front',
      bestAngleDescription: json['bestAngleDescription'] as String? ?? '',
      facialFeatures: Map<String, double>.from(
        json['facialFeatures'] as Map? ?? {},
      ),
      overallAnalysis: json['overallAnalysis'] as String? ?? '',
      imageBase64: json['imageBase64'] as String? ?? '',
      source: json['source'] != null
          ? AnalysisSource.values.firstWhere(
              (e) => e.toString() == json['source'],
              orElse: () => AnalysisSource.api,
            )
          : AnalysisSource.api,
    );
  }
}

