import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../models/face_analysis_result.dart';

class LocalFaceAnalysisService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<FaceAnalysisResult> analyzeFaceOffline(String imageBase64) async {
    try {
      // Decode base64 string to bytes
      final decodedBytes = base64Decode(imageBase64);
      
      if (decodedBytes.isEmpty) {
        return _generateSimulatedResult(imageBase64);
      }

      // Decode image
      final image = img.decodeImage(decodedBytes);
      if (image == null) {
        return _generateSimulatedResult(imageBase64);
      }

      // Convert to InputImage for ML Kit
      // Use yuv420 format for bytes (most common for ML Kit)
      final inputImage = InputImage.fromBytes(
        bytes: decodedBytes,
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.width * 4,
        ),
      );

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return _generateSimulatedResult(imageBase64, reason: 'No face detected');
      }

      // Use the first detected face
      final face = faces.first;

      // Analyze face features
      final result = _analyzeFaceFeatures(face, image, imageBase64);
      return FaceAnalysisResult(
        attractivenessScore: result.attractivenessScore,
        bestAngle: result.bestAngle,
        bestAngleDescription: result.bestAngleDescription,
        facialFeatures: result.facialFeatures,
        overallAnalysis: result.overallAnalysis,
        imageBase64: result.imageBase64,
        source: AnalysisSource.localML,
      );
    } catch (e) {
      // If ML Kit fails, use simulated
      return _generateSimulatedResult(imageBase64, reason: 'ML Kit error: $e');
    }
  }

  FaceAnalysisResult _analyzeFaceFeatures(
    Face face,
    img.Image image,
    String imageBase64,
  ) {
    // Calculate facial symmetry
    final symmetry = _calculateSymmetry(face);
    
    // Calculate facial structure score
    final facialStructure = _calculateFacialStructure(face, image);
    
    // Estimate skin quality (based on face detection confidence and landmarks)
    final skinQuality = _estimateSkinQuality(face);
    
    // Calculate eye area score
    final eyeArea = _calculateEyeArea(face);
    
    // Calculate nose score
    final nose = _calculateNoseScore(face);
    
    // Calculate lips score
    final lips = _calculateLipsScore(face);
    
    // Calculate overall attractiveness
    final attractivenessScore = _calculateAttractiveness(
      symmetry,
      facialStructure,
      skinQuality,
      eyeArea,
      nose,
      lips,
    );
    
    // Determine best angle
    final bestAngle = _determineBestAngle(face, image);
    
    return FaceAnalysisResult(
      attractivenessScore: attractivenessScore,
      bestAngle: bestAngle['angle'] as String,
      bestAngleDescription: bestAngle['description'] as String,
      facialFeatures: {
        'symmetry': symmetry,
        'skinQuality': skinQuality,
        'facialStructure': facialStructure,
        'eyeArea': eyeArea,
        'nose': nose,
        'lips': lips,
      },
      overallAnalysis: _generateOverallAnalysis(
        attractivenessScore,
        symmetry,
        facialStructure,
        skinQuality,
      ),
      imageBase64: imageBase64,
    );
  }

  double _calculateSymmetry(Face face) {
    if (face.landmarks.isEmpty) return 75.0;
    
    // Calculate symmetry based on landmark positions
    double symmetryScore = 80.0;
    
    // Check if left and right landmarks are balanced
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    
    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();
      final faceWidth = face.boundingBox.width;
      final eyeRatio = eyeDistance / faceWidth;
      
      // Ideal eye ratio is around 0.4-0.5
      if (eyeRatio >= 0.4 && eyeRatio <= 0.5) {
        symmetryScore += 10;
      } else if (eyeRatio >= 0.35 && eyeRatio <= 0.55) {
        symmetryScore += 5;
      }
    }
    
    return symmetryScore.clamp(0.0, 100.0);
  }

  double _calculateFacialStructure(Face face, img.Image image) {
    // Calculate based on face proportions
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final aspectRatio = faceWidth / faceHeight;
    
    // Ideal face ratio is around 0.7-0.8 (oval face)
    double score = 75.0;
    
    if (aspectRatio >= 0.7 && aspectRatio <= 0.8) {
      score = 90.0;
    } else if (aspectRatio >= 0.65 && aspectRatio <= 0.85) {
      score = 85.0;
    } else if (aspectRatio >= 0.6 && aspectRatio <= 0.9) {
      score = 80.0;
    } else {
      score = 70.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _estimateSkinQuality(Face face) {
    // Base score on face detection confidence and smoothness
    double score = 70.0;
    
    // Higher tracking ID confidence suggests better skin quality
    if (face.trackingId != null) {
      score += 10;
    }
    
    // If landmarks are well detected, skin is likely clear
    if (face.landmarks.length >= 5) {
      score += 10;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateEyeArea(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    
    if (leftEye == null || rightEye == null) return 75.0;
    
    // Calculate eye size relative to face
    final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();
    final faceWidth = face.boundingBox.width;
    final eyeRatio = eyeDistance / faceWidth;
    
    // Ideal eye ratio is around 0.4-0.5
    double score = 75.0;
    if (eyeRatio >= 0.4 && eyeRatio <= 0.5) {
      score = 90.0;
    } else if (eyeRatio >= 0.35 && eyeRatio <= 0.55) {
      score = 85.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateNoseScore(Face face) {
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    if (noseBase == null) return 75.0;
    
    // Calculate nose position relative to face center
    final faceCenterX = face.boundingBox.left + face.boundingBox.width / 2;
    final noseOffset = (noseBase.position.x - faceCenterX).abs();
    final faceWidth = face.boundingBox.width;
    final noseRatio = noseOffset / faceWidth;
    
    // Ideal nose is centered (low ratio)
    double score = 80.0;
    if (noseRatio < 0.05) {
      score = 95.0;
    } else if (noseRatio < 0.1) {
      score = 90.0;
    } else if (noseRatio < 0.15) {
      score = 85.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateLipsScore(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    
    if (leftMouth == null || rightMouth == null || bottomMouth == null) {
      return 75.0;
    }
    
    // Calculate lip symmetry
    final mouthWidth = (leftMouth.position.x - rightMouth.position.x).abs();
    final faceWidth = face.boundingBox.width;
    final mouthRatio = mouthWidth / faceWidth;
    
    // Ideal mouth ratio is around 0.4-0.5
    double score = 75.0;
    if (mouthRatio >= 0.4 && mouthRatio <= 0.5) {
      score = 90.0;
    } else if (mouthRatio >= 0.35 && mouthRatio <= 0.55) {
      score = 85.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateAttractiveness(
    double symmetry,
    double facialStructure,
    double skinQuality,
    double eyeArea,
    double nose,
    double lips,
  ) {
    // Weighted average
    final attractiveness = (
      symmetry * 0.25 +
      facialStructure * 0.20 +
      skinQuality * 0.20 +
      eyeArea * 0.15 +
      nose * 0.10 +
      lips * 0.10
    );
    
    return attractiveness.clamp(0.0, 100.0);
  }

  Map<String, String> _determineBestAngle(Face face, img.Image image) {
    // Analyze face position to determine best angle
    final faceCenterX = face.boundingBox.left + face.boundingBox.width / 2;
    final imageCenterX = image.width / 2;
    final offset = faceCenterX - imageCenterX;
    final offsetRatio = offset / image.width;
    
    String angle;
    String description;
    
    if (offsetRatio.abs() < 0.05) {
      angle = 'Front';
      description = 'Your front-facing angle showcases excellent facial symmetry. The balanced proportions and centered features create a harmonious and appealing appearance.';
    } else if (offsetRatio > 0.1) {
      angle = 'Left Profile';
      description = 'Your left profile angle highlights your facial structure beautifully. The side view emphasizes your jawline and creates an elegant silhouette.';
    } else if (offsetRatio < -0.1) {
      angle = 'Right Profile';
      description = 'Your right profile angle accentuates your facial features. This angle creates depth and dimension, showcasing your best side.';
    } else if (offsetRatio > 0.05) {
      angle = 'Three-Quarter Left';
      description = 'Your three-quarter left angle is particularly flattering. This angle combines the best of front and profile views, creating visual interest and appeal.';
    } else {
      angle = 'Three-Quarter Right';
      description = 'Your three-quarter right angle creates an attractive perspective. This angle balances facial features while adding depth and character.';
    }
    
    return {'angle': angle, 'description': description};
  }

  String _generateOverallAnalysis(
    double attractiveness,
    double symmetry,
    double facialStructure,
    double skinQuality,
  ) {
    final buffer = StringBuffer();
    
    if (attractiveness >= 85) {
      buffer.write('Your face demonstrates exceptional attractiveness with ');
    } else if (attractiveness >= 75) {
      buffer.write('Your face shows strong attractiveness with ');
    } else if (attractiveness >= 65) {
      buffer.write('Your face displays good attractiveness with ');
    } else {
      buffer.write('Your face has potential with ');
    }
    
    if (symmetry >= 85) {
      buffer.write('excellent symmetry, ');
    } else if (symmetry >= 75) {
      buffer.write('good symmetry, ');
    } else {
      buffer.write('moderate symmetry, ');
    }
    
    if (facialStructure >= 85) {
      buffer.write('well-proportioned facial structure, ');
    } else if (facialStructure >= 75) {
      buffer.write('balanced facial structure, ');
    } else {
      buffer.write('adequate facial structure, ');
    }
    
    if (skinQuality >= 80) {
      buffer.write('and clear skin quality. ');
    } else if (skinQuality >= 70) {
      buffer.write('and decent skin quality. ');
    } else {
      buffer.write('and room for skin improvement. ');
    }
    
    buffer.write('Maintaining a consistent skincare routine will help preserve and enhance these features.');
    
    return buffer.toString();
  }

  FaceAnalysisResult _generateSimulatedResult(
    String imageBase64, {
    String? reason,
  }) {
    final result = _generateSimulatedResultInternal(imageBase64, reason: reason);
    return FaceAnalysisResult(
      attractivenessScore: result.attractivenessScore,
      bestAngle: result.bestAngle,
      bestAngleDescription: result.bestAngleDescription,
      facialFeatures: result.facialFeatures,
      overallAnalysis: result.overallAnalysis,
      imageBase64: result.imageBase64,
      source: AnalysisSource.simulated,
    );
  }

  FaceAnalysisResult _generateSimulatedResultInternal(
    String imageBase64, {
    String? reason,
  }) {
    // More realistic simulated analysis
    final attractiveness = 72.0 + (DateTime.now().millisecond % 18);
    final angles = [
      {'angle': 'Front', 'desc': 'Your front-facing angle showcases balanced facial symmetry and highlights your best features. The lighting and angle create an appealing visual harmony.'},
      {'angle': 'Left Profile', 'desc': 'Your left profile angle emphasizes your facial structure beautifully. The side view creates depth and showcases your jawline elegantly.'},
      {'angle': 'Right Profile', 'desc': 'Your right profile angle accentuates your facial features. This angle creates visual interest and highlights your best side.'},
      {'angle': 'Three-Quarter Left', 'desc': 'Your three-quarter left angle is particularly flattering. This angle combines front and profile views, creating an attractive perspective.'},
      {'angle': 'Three-Quarter Right', 'desc': 'Your three-quarter right angle creates depth and dimension. This angle balances your features while adding character.'},
    ];
    final bestAngle = angles[DateTime.now().millisecond % angles.length];
    
    return FaceAnalysisResult(
      attractivenessScore: attractiveness,
      bestAngle: bestAngle['angle'] as String,
      bestAngleDescription: bestAngle['desc'] as String,
      facialFeatures: {
        'symmetry': 78.0 + (DateTime.now().millisecond % 8),
        'skinQuality': 75.0 + (DateTime.now().millisecond % 10),
        'facialStructure': 80.0 + (DateTime.now().millisecond % 6),
        'eyeArea': 82.0 + (DateTime.now().millisecond % 8),
        'nose': 76.0 + (DateTime.now().millisecond % 6),
        'lips': 79.0 + (DateTime.now().millisecond % 7),
      },
      overallAnalysis: 'Your face shows good overall symmetry and balanced features. The facial structure is well-proportioned with clear skin tone. Consider maintaining good skincare routine for optimal appearance.',
      imageBase64: imageBase64,
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}

