import 'dart:ui';

/// Capture task types for multi-angle capture
enum CaptureTaskType {
  topView,
  sideView,
  closeUp,
  wideAngle,
  stageSpecific,
}

/// Growth stage classification
enum CropGrowthStage {
  unknown,
  sowing,
  germination,
  seedling,
  vegetative,
  flowering,
  fruiting,
  maturity,
  harvest,
  harvested,
}

/// Image quality status
enum QualityStatus {
  good,
  warning,
  error,
}

/// Validation check types
enum ValidationCheck {
  distance,
  angle,
  tilt,
  blur,
  exposure,
  gps,
  segmentation,
  stability,
}

/// AR guidance colors
class ARColors {
  static const Color valid = Color(0xFF4CAF50);       // Green
  static const Color warning = Color(0xFFFF9800);     // Orange
  static const Color error = Color(0xFFF44336);       // Red
  static const Color neutral = Color(0xFF2196F3);    // Blue
  static const Color ghost = Color(0x4DFFFFFF);       // Semi-transparent white
  static const Color overlay = Color(0x30000000);     // Very light semi-transparent black (reduced from 0x80)
}

/// Exposure status
enum ExposureStatus {
  underexposed,
  normal,
  overexposed,
}

/// Distance estimation result
class DistanceEstimate {
  final double distanceMeters;
  final DistanceStatus status;
  final String message;
  final double confidence;

  const DistanceEstimate({
    required this.distanceMeters,
    required this.status,
    required this.message,
    this.confidence = 0.8,
  });

  static const double idealMinDistance = 0.3;  // 30cm
  static const double idealMaxDistance = 1.5;  // 150cm

  factory DistanceEstimate.fromDistance(double distance) {
    if (distance < idealMinDistance) {
      return DistanceEstimate(
        distanceMeters: distance,
        status: DistanceStatus.tooClose,
        message: 'Move back',
      );
    } else if (distance > idealMaxDistance) {
      return DistanceEstimate(
        distanceMeters: distance,
        status: DistanceStatus.tooFar,
        message: 'Move closer',
      );
    } else {
      return DistanceEstimate(
        distanceMeters: distance,
        status: DistanceStatus.optimal,
        message: 'Perfect distance',
      );
    }
  }
}

enum DistanceStatus {
  tooClose,
  optimal,
  tooFar,
}

/// Angle/Tilt estimation result
class TiltEstimate {
  final double pitchDegrees;   // Forward/backward tilt
  final double rollDegrees;    // Left/right tilt
  final TiltStatus status;
  final String message;
  final TiltDirection? nudgeDirection;

  const TiltEstimate({
    required this.pitchDegrees,
    required this.rollDegrees,
    required this.status,
    required this.message,
    this.nudgeDirection,
  });

  static const double maxAcceptableTilt = 15.0;  // degrees

  factory TiltEstimate.fromAngles(double pitch, double roll) {
    final absPitch = pitch.abs();
    final absRoll = roll.abs();

    TiltDirection? direction;
    String message = 'Level';
    TiltStatus status = TiltStatus.level;

    if (absPitch > maxAcceptableTilt || absRoll > maxAcceptableTilt) {
      status = TiltStatus.tilted;
      
      if (absPitch > absRoll) {
        direction = pitch > 0 ? TiltDirection.tiltBack : TiltDirection.tiltForward;
        message = pitch > 0 ? 'Tilt forward' : 'Tilt back';
      } else {
        direction = roll > 0 ? TiltDirection.tiltLeft : TiltDirection.tiltRight;
        message = roll > 0 ? 'Tilt left' : 'Tilt right';
      }
    }

    return TiltEstimate(
      pitchDegrees: pitch,
      rollDegrees: roll,
      status: status,
      message: message,
      nudgeDirection: direction,
    );
  }
}

enum TiltStatus {
  level,
  slightlyTilted,
  tilted,
}

enum TiltDirection {
  tiltLeft,
  tiltRight,
  tiltForward,
  tiltBack,
}

/// Image quality analysis result
class ImageQualityResult {
  final double blurScore;          // 0-100, higher is sharper
  final double exposureScore;      // 0-100, 50 is ideal
  final double brightnessScore;    // 0-100
  final bool hasBacklight;
  final ExposureStatus exposureStatus;
  final QualityStatus overallStatus;
  final List<String> warnings;

  const ImageQualityResult({
    required this.blurScore,
    required this.exposureScore,
    required this.brightnessScore,
    required this.hasBacklight,
    this.exposureStatus = ExposureStatus.normal,
    required this.overallStatus,
    required this.warnings,
  });

  bool get isBlurry => blurScore < minBlurScore;

  static const double minBlurScore = 30.0;
  static const double minExposureScore = 20.0;
  static const double maxExposureScore = 80.0;

  factory ImageQualityResult.analyze({
    required double blurScore,
    required double exposureScore,
    required double brightnessScore,
    required bool hasBacklight,
  }) {
    final warnings = <String>[];
    QualityStatus status = QualityStatus.good;

    if (blurScore < minBlurScore) {
      warnings.add('Hold still - image is blurry');
      status = QualityStatus.error;
    }

    if (exposureScore < minExposureScore) {
      warnings.add('Too dark - move to sunlight');
      status = status == QualityStatus.error ? status : QualityStatus.warning;
    } else if (exposureScore > maxExposureScore) {
      warnings.add('Too bright - find shade');
      status = status == QualityStatus.error ? status : QualityStatus.warning;
    }

    if (hasBacklight) {
      warnings.add('Backlight detected - face the sun');
      status = status == QualityStatus.error ? status : QualityStatus.warning;
    }

    if (brightnessScore < 20) {
      warnings.add('Very low light');
      status = QualityStatus.error;
    }

    return ImageQualityResult(
      blurScore: blurScore,
      exposureScore: exposureScore,
      brightnessScore: brightnessScore,
      hasBacklight: hasBacklight,
      overallStatus: warnings.isEmpty ? QualityStatus.good : status,
      warnings: warnings,
    );
  }
}

/// GPS verification result
class GpsVerificationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isInsideFarmBoundary;
  final double distanceFromBoundary;
  final GpsStatus status;
  final String message;

  const GpsVerificationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.isInsideFarmBoundary,
    required this.distanceFromBoundary,
    required this.status,
    required this.message,
  });

  factory GpsVerificationResult.noFix() {
    return GpsVerificationResult(
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      timestamp: DateTime.now(),
      isInsideFarmBoundary: false,
      distanceFromBoundary: 0,
      status: GpsStatus.noFix,
      message: 'Acquiring GPS...',
    );
  }
}

enum GpsStatus {
  noFix,
  lowAccuracy,
  insideBoundary,
  outsideBoundary,
}

/// Crop segmentation result
class CropSegmentationResult {
  final bool cropDetected;
  final Rect? cropBoundingBox;
  final double coverage;           // 0-1, percentage of frame covered by crop
  final String? detectedCropType;
  final CropGrowthStage? detectedStage;
  final double confidence;
  final SegmentationStatus status;

  const CropSegmentationResult({
    required this.cropDetected,
    this.cropBoundingBox,
    required this.coverage,
    this.detectedCropType,
    this.detectedStage,
    required this.confidence,
    required this.status,
  });

  factory CropSegmentationResult.noCrop() {
    return const CropSegmentationResult(
      cropDetected: false,
      coverage: 0,
      confidence: 0,
      status: SegmentationStatus.noCropDetected,
    );
  }
}

enum SegmentationStatus {
  noCropDetected,
  partialCoverage,
  goodCoverage,
  tooMuchCoverage,
}

/// Capture task with AR constraints
class CaptureTask {
  final String id;
  final CaptureTaskType type;
  final String title;
  final String description;
  final String? ghostImageAsset;
  final double requiredMinPitch;
  final double requiredMaxPitch;
  final double requiredMinRoll;
  final double requiredMaxRoll;
  final double requiredMinDistance;
  final double requiredMaxDistance;
  final bool requiresGpsVerification;
  final bool completed;
  final String? capturedImagePath;

  const CaptureTask({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.ghostImageAsset,
    this.requiredMinPitch = -15,
    this.requiredMaxPitch = 15,
    this.requiredMinRoll = -15,
    this.requiredMaxRoll = 15,
    this.requiredMinDistance = 0.3,
    this.requiredMaxDistance = 1.5,
    this.requiresGpsVerification = true,
    this.completed = false,
    this.capturedImagePath,
  });

  CaptureTask copyWith({
    bool? completed,
    String? capturedImagePath,
  }) {
    return CaptureTask(
      id: id,
      type: type,
      title: title,
      description: description,
      ghostImageAsset: ghostImageAsset,
      requiredMinPitch: requiredMinPitch,
      requiredMaxPitch: requiredMaxPitch,
      requiredMinRoll: requiredMinRoll,
      requiredMaxRoll: requiredMaxRoll,
      requiredMinDistance: requiredMinDistance,
      requiredMaxDistance: requiredMaxDistance,
      requiresGpsVerification: requiresGpsVerification,
      completed: completed ?? this.completed,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
    );
  }

  /// Get predefined capture tasks for crop insurance - simple farmer-friendly tasks
  static List<CaptureTask> getStandardTasks() {
    return [
      const CaptureTask(
        id: 'full_plant',
        type: CaptureTaskType.sideView,
        title: 'Full Plant Photo',
        description: 'Stand 2-3 feet away and take a photo of the whole plant',
      ),
      const CaptureTask(
        id: 'leaf_photo',
        type: CaptureTaskType.closeUp,
        title: 'Leaf Close-up',
        description: 'Move close to a leaf and take its photo clearly',
      ),
      const CaptureTask(
        id: 'field_view',
        type: CaptureTaskType.wideAngle,
        title: 'Field View',
        description: 'Step back and capture your entire crop field',
      ),
      const CaptureTask(
        id: 'damage_photo',
        type: CaptureTaskType.closeUp,
        title: 'Damage/Problem Area',
        description: 'If any damage, take a clear photo of the affected area',
      ),
    ];
  }

  /// Alias for getStandardTasks for compatibility
  static List<CaptureTask> get standardMultiAngleTasks => getStandardTasks();

  /// Get instruction text
  String get instruction => description;
}

/// Overall validation state
class ValidationState {
  final DistanceEstimate? distance;
  final TiltEstimate? tilt;
  final ImageQualityResult? imageQuality;
  final GpsVerificationResult? gps;
  final CropSegmentationResult? segmentation;
  final bool isStable;
  final DateTime timestamp;

  const ValidationState({
    this.distance,
    this.tilt,
    this.imageQuality,
    this.gps,
    this.segmentation,
    this.isStable = false,
    required this.timestamp,
  });

  /// Check if all validations pass
  bool get allValidationsPassed {
    bool passed = true;

    if (distance != null && distance!.status != DistanceStatus.optimal) {
      passed = false;
    }
    if (tilt != null && tilt!.status == TiltStatus.tilted) {
      passed = false;
    }
    if (imageQuality != null && imageQuality!.overallStatus == QualityStatus.error) {
      passed = false;
    }
    if (gps != null && gps!.status == GpsStatus.outsideBoundary) {
      passed = false;
    }
    if (!isStable) {
      passed = false;
    }

    return passed;
  }

  /// Get list of failed validations
  List<String> get failedValidations {
    final failed = <String>[];

    if (distance != null && distance!.status != DistanceStatus.optimal) {
      failed.add(distance!.message);
    }
    if (tilt != null && tilt!.status == TiltStatus.tilted) {
      failed.add(tilt!.message);
    }
    if (imageQuality != null) {
      failed.addAll(imageQuality!.warnings);
    }
    if (gps != null && gps!.status == GpsStatus.outsideBoundary) {
      failed.add('Outside farm boundary');
    }
    if (!isStable) {
      failed.add('Hold steady');
    }

    return failed;
  }

  ValidationState copyWith({
    DistanceEstimate? distance,
    TiltEstimate? tilt,
    ImageQualityResult? imageQuality,
    GpsVerificationResult? gps,
    CropSegmentationResult? segmentation,
    bool? isStable,
  }) {
    return ValidationState(
      distance: distance ?? this.distance,
      tilt: tilt ?? this.tilt,
      imageQuality: imageQuality ?? this.imageQuality,
      gps: gps ?? this.gps,
      segmentation: segmentation ?? this.segmentation,
      isStable: isStable ?? this.isStable,
      timestamp: DateTime.now(),
    );
  }
}
