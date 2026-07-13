import 'dart:async';
import 'dart:collection';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/ar_camera_models.dart';
import 'image_quality_analyzer.dart';

/// Validation thresholds configuration
class ValidationThresholds {
  /// Minimum blur score for acceptable image (0-100)
  final double minBlurScore;
  
  /// Minimum exposure score for acceptable image (0-100)
  final double minExposureScore;
  
  /// Maximum tilt angle in degrees for level shot
  final double maxTiltAngle;
  
  /// Required stable duration in milliseconds
  final int stableDurationMs;
  
  /// Optimal distance range in meters
  final double minDistance;
  final double maxDistance;
  
  /// GPS accuracy threshold in meters
  final double gpsAccuracyThreshold;

  const ValidationThresholds({
    this.minBlurScore = 40.0,
    this.minExposureScore = 30.0,
    this.maxTiltAngle = 15.0,
    this.stableDurationMs = 500,
    this.minDistance = 0.5,
    this.maxDistance = 3.0,
    this.gpsAccuracyThreshold = 10.0,
  });

  static const ValidationThresholds standard = ValidationThresholds();
  
  static const ValidationThresholds strict = ValidationThresholds(
    minBlurScore: 60.0,
    minExposureScore: 50.0,
    maxTiltAngle: 10.0,
    stableDurationMs: 750,
    gpsAccuracyThreshold: 5.0,
  );
  
  static const ValidationThresholds relaxed = ValidationThresholds(
    minBlurScore: 25.0,
    minExposureScore: 20.0,
    maxTiltAngle: 25.0,
    stableDurationMs: 300,
    gpsAccuracyThreshold: 20.0,
  );
}

/// Callback for validation state updates
typedef ValidationCallback = void Function(ValidationState state);

/// Main validation engine that orchestrates all quality checks
class ValidationEngine {
  final ValidationThresholds thresholds;
  final ImageQualityAnalyzer _qualityAnalyzer;
  final StabilityTracker _stabilityTracker;
  
  ValidationCallback? onValidationUpdate;
  
  // Current state
  ValidationState _currentState = ValidationState(timestamp: DateTime.now());
  ValidationState get currentState => _currentState;
  
  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // GPS tracking
  Position? _currentPosition;
  List<Position>? _farmBoundary;
  
  // Distance estimation (using device sensors or ML)
  DistanceEstimate? _lastDistanceEstimate;
  
  // Tilt tracking
  double _currentPitch = 0.0;
  double _currentRoll = 0.0;
  
  // Frame processing throttle
  DateTime? _lastFrameProcess;
  static const _frameProcessInterval = Duration(milliseconds: 100);
  
  // Quality history for smoothing
  final Queue<ImageQualityResult> _qualityHistory = Queue();
  static const _qualityHistorySize = 5;
  
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  ValidationEngine({
    this.thresholds = ValidationThresholds.standard,
    this.onValidationUpdate,
  })  : _qualityAnalyzer = ImageQualityAnalyzer(),
        _stabilityTracker = StabilityTracker();

  /// Start validation engine
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    
    // Start sensor subscriptions
    _startSensorListeners();
    
    // Initialize GPS if needed
    await _initializeGps();
  }

  /// Stop validation engine
  void stop() {
    _isRunning = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _qualityHistory.clear();
  }

  /// Process a camera frame for quality analysis
  Future<void> processFrame(CameraImage image) async {
    if (!_isRunning) return;
    
    // Throttle frame processing
    final now = DateTime.now();
    if (_lastFrameProcess != null &&
        now.difference(_lastFrameProcess!) < _frameProcessInterval) {
      return;
    }
    _lastFrameProcess = now;
    
    // Analyze image quality
    final qualityResult = await _qualityAnalyzer.analyzeImage(image);
    
    // Add to history for smoothing
    _qualityHistory.addLast(qualityResult);
    if (_qualityHistory.length > _qualityHistorySize) {
      _qualityHistory.removeFirst();
    }
    
    // Get smoothed quality result
    final smoothedQuality = _getSmoothedQuality();
    
    // Update validation state
    _updateState(quality: smoothedQuality);
  }

  /// Update distance estimation (from ML or sensor data)
  void updateDistanceEstimate(double estimatedMeters, double confidence) {
    _lastDistanceEstimate = DistanceEstimate(
      distanceMeters: estimatedMeters,
      status: estimatedMeters < thresholds.minDistance 
          ? DistanceStatus.tooClose 
          : (estimatedMeters > thresholds.maxDistance ? DistanceStatus.tooFar : DistanceStatus.optimal),
      message: estimatedMeters < thresholds.minDistance 
          ? 'Move back' 
          : (estimatedMeters > thresholds.maxDistance ? 'Move closer' : 'Good distance'),
      confidence: confidence,
    );
    _updateState(distance: _lastDistanceEstimate);
  }

  /// Update GPS position
  void updateGpsPosition(Position position) {
    _currentPosition = position;
    _updateGpsVerification();
  }

  /// Set farm boundary for GPS verification
  void setFarmBoundary(List<Position> boundary) {
    _farmBoundary = boundary;
    _updateGpsVerification();
  }

  /// Update crop segmentation result
  void updateSegmentation(CropSegmentationResult segmentation) {
    _updateState(segmentation: segmentation);
  }

  /// Check if capture is allowed based on current validation
  /// Always returns true - quality checks are done after capture, not before
  bool canCapture() {
    // Always allow capture - blur detection happens after image is captured
    // Quality warnings are shown but don't block the capture action
    return true;
  }

  /// Check if current state has any quality warnings
  bool hasQualityWarnings() {
    final state = _currentState;
    
    if (state.imageQuality != null) {
      if (state.imageQuality!.overallStatus == QualityStatus.error) {
        return true;
      }
    }
    
    if (state.tilt != null) {
      if (state.tilt!.status == TiltStatus.tilted) {
        return true;
      }
    }
    
    if (!state.isStable) {
      return true;
    }
    
    return false;
  }

  /// Get list of warning messages (non-blocking)
  /// Distance, tilt, and quality issues are just informational
  List<String> getWarningMessages() {
    final warnings = <String>[];
    final state = _currentState;
    
    // Distance warnings (non-blocking)
    if (state.distance != null) {
      switch (state.distance!.status) {
        case DistanceStatus.tooClose:
          warnings.add('Too close - consider moving back');
          break;
        case DistanceStatus.tooFar:
          warnings.add('Too far - consider moving closer');
          break;
        case DistanceStatus.optimal:
          warnings.add('Distance: Optimal');
          break;
      }
    }
    
    // Tilt warnings (non-blocking)
    if (state.tilt != null && state.tilt!.status == TiltStatus.tilted) {
      warnings.add('Camera tilted - try holding level');
    }
    
    // Quality warnings (non-blocking)
    if (state.imageQuality != null) {
      if (state.imageQuality!.isBlurry) {
        warnings.add('Image may be blurry');
      }
      if (state.imageQuality!.exposureStatus == ExposureStatus.overexposed) {
        warnings.add('Too bright');
      }
      if (state.imageQuality!.exposureStatus == ExposureStatus.underexposed) {
        warnings.add('Too dark');
      }
      if (state.imageQuality!.hasBacklight) {
        warnings.add('Backlight detected');
      }
    }
    
    // Stability warnings (non-blocking)
    if (!state.isStable) {
      warnings.add('Hold camera steady');
    }
    
    // GPS warnings (optional, non-blocking)
    if (state.gps != null && state.gps!.status == GpsStatus.outsideBoundary) {
      warnings.add('Outside farm boundary');
    }
    
    return warnings;
  }
  
  /// Legacy method name for backward compatibility
  @Deprecated('Use getWarningMessages() instead')
  List<String> getCaptureBlockers() => getWarningMessages();

  /// Get validation score as percentage (0-100)
  double getValidationScore() {
    double score = 100.0;
    final state = _currentState;
    
    // Quality contribution (40%)
    if (state.imageQuality != null) {
      final qualityScore = (state.imageQuality!.blurScore + 
          state.imageQuality!.exposureScore) / 2;
      score *= (qualityScore / 100) * 0.4 + 0.6;
    }
    
    // Stability contribution (20%)
    if (!state.isStable) {
      score *= 0.8;
    }
    
    // Tilt contribution (20%)
    if (state.tilt != null) {
      switch (state.tilt!.status) {
        case TiltStatus.level:
          break; // No penalty
        case TiltStatus.slightlyTilted:
          score *= 0.9;
          break;
        case TiltStatus.tilted:
          score *= 0.7;
          break;
      }
    }
    
    // Distance contribution (20%)
    if (state.distance != null && 
        state.distance!.status != DistanceStatus.optimal) {
      score *= 0.8;
    }
    
    return score.clamp(0.0, 100.0);
  }

  void _startSensorListeners() {
    // Accelerometer for stability and tilt
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _stabilityTracker.addSample(event.x, event.y, event.z);
      
      // Calculate pitch and roll from accelerometer
      _currentPitch = _calculatePitch(event.x, event.y, event.z);
      _currentRoll = _calculateRoll(event.x, event.y, event.z);
      
      _updateTilt();
    });
    
    // Gyroscope for additional shake detection
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      // Could use for shake detection enhancement
    });
  }

  double _calculatePitch(double x, double y, double z) {
    // Calculate pitch (forward/backward tilt) in degrees
    final pitch = _toDegrees(
      _atan2(-x, _sqrt(y * y + z * z))
    );
    return pitch;
  }

  double _calculateRoll(double x, double y, double z) {
    // Calculate roll (left/right tilt) in degrees
    final roll = _toDegrees(_atan2(y, z));
    return roll;
  }

  double _toDegrees(double radians) => radians * 180 / 3.14159265359;
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  double _atan(double x) {
    // Taylor series approximation
    if (x.abs() <= 1) {
      double result = x;
      double term = x;
      for (int i = 1; i <= 10; i++) {
        term *= -x * x;
        result += term / (2 * i + 1);
      }
      return result;
    } else {
      return (3.14159265359 / 2) - _atan(1 / x);
    }
  }
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  void _updateTilt() {
    TiltStatus status;
    final maxAngle = thresholds.maxTiltAngle;
    final totalTilt = _sqrt(_currentPitch * _currentPitch + _currentRoll * _currentRoll);
    
    if (totalTilt <= maxAngle * 0.5) {
      status = TiltStatus.level;
    } else if (totalTilt <= maxAngle) {
      status = TiltStatus.slightlyTilted;
    } else {
      status = TiltStatus.tilted;
    }
    
    String message = 'Level';
    TiltDirection? direction;
    if (status == TiltStatus.tilted || status == TiltStatus.slightlyTilted) {
      if (_currentPitch.abs() > _currentRoll.abs()) {
        direction = _currentPitch > 0 ? TiltDirection.tiltBack : TiltDirection.tiltForward;
        message = _currentPitch > 0 ? 'Tilt forward' : 'Tilt back';
      } else {
        direction = _currentRoll > 0 ? TiltDirection.tiltLeft : TiltDirection.tiltRight;
        message = _currentRoll > 0 ? 'Tilt left' : 'Tilt right';
      }
    }
    
    final tilt = TiltEstimate(
      pitchDegrees: _currentPitch,
      rollDegrees: _currentRoll,
      status: status,
      message: message,
      nudgeDirection: direction,
    );
    
    _updateState(tilt: tilt);
  }

  Future<void> _initializeGps() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = position;
      _updateGpsVerification();
    } catch (e) {
      // GPS not available
      _updateState(
        gps: GpsVerificationResult(
          latitude: 0,
          longitude: 0,
          accuracy: 0,
          timestamp: DateTime.now(),
          isInsideFarmBoundary: false,
          distanceFromBoundary: 0,
          status: GpsStatus.noFix,
          message: 'GPS not available',
        ),
      );
    }
  }

  void _updateGpsVerification() {
    if (_currentPosition == null) {
      _updateState(
        gps: GpsVerificationResult(
          latitude: 0,
          longitude: 0,
          accuracy: 0,
          timestamp: DateTime.now(),
          isInsideFarmBoundary: false,
          distanceFromBoundary: 0,
          status: GpsStatus.noFix,
          message: 'Acquiring GPS...',
        ),
      );
      return;
    }
    
    bool isInside = true;
    if (_farmBoundary != null && _farmBoundary!.isNotEmpty) {
      isInside = _isPointInPolygon(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _farmBoundary!,
      );
    }
    
    final gpsResult = GpsVerificationResult(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      accuracy: _currentPosition!.accuracy,
      timestamp: DateTime.now(),
      isInsideFarmBoundary: isInside,
      distanceFromBoundary: 0, // TODO: Calculate distance from boundary
      status: isInside ? GpsStatus.insideBoundary : GpsStatus.outsideBoundary,
      message: isInside ? 'Inside farm boundary' : 'Outside farm boundary',
    );
    
    _updateState(gps: gpsResult);
  }

  bool _isPointInPolygon(double lat, double lng, List<Position> polygon) {
    // Ray casting algorithm for point-in-polygon
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].longitude > lng) != (polygon[j].longitude > lng)) &&
          (lat < (polygon[j].latitude - polygon[i].latitude) * 
           (lng - polygon[i].longitude) / 
           (polygon[j].longitude - polygon[i].longitude) + 
           polygon[i].latitude)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }

  ImageQualityResult _getSmoothedQuality() {
    if (_qualityHistory.isEmpty) {
      return const ImageQualityResult(
        blurScore: 0,
        exposureScore: 0,
        brightnessScore: 0,
        hasBacklight: false,
        overallStatus: QualityStatus.warning,
        warnings: ['No quality data'],
      );
    }
    
    if (_qualityHistory.length == 1) {
      return _qualityHistory.first;
    }
    
    // Average the scores
    double totalBlur = 0;
    double totalExposure = 0;
    int blurryCount = 0;
    int backlightCount = 0;
    
    for (final result in _qualityHistory) {
      totalBlur += result.blurScore;
      totalExposure += result.exposureScore;
      if (result.isBlurry) blurryCount++;
      if (result.hasBacklight) backlightCount++;
    }
    
    final count = _qualityHistory.length;
    final avgBlur = totalBlur / count;
    final avgExposure = totalExposure / count;
    
    // Use majority voting for boolean flags
    final isBlurry = blurryCount > count / 2;
    final hasBacklight = backlightCount > count / 2;
    
    final warnings = <String>[];
    if (isBlurry) warnings.add('Image appears blurry');
    if (hasBacklight) warnings.add('Backlight detected');
    if (avgExposure < 30) warnings.add('Low exposure');
    if (avgExposure > 90) warnings.add('Overexposed');
    
    // Determine overall status
    QualityStatus overallStatus = QualityStatus.good;
    if (isBlurry || avgExposure < 20 || avgExposure > 90) {
      overallStatus = QualityStatus.error;
    } else if (hasBacklight || avgExposure < 30 || avgExposure > 80) {
      overallStatus = QualityStatus.warning;
    }
    
    return ImageQualityResult(
      blurScore: avgBlur,
      exposureScore: avgExposure,
      brightnessScore: avgExposure,
      hasBacklight: hasBacklight,
      overallStatus: overallStatus,
      warnings: warnings,
    );
  }

  void _updateState({
    ImageQualityResult? quality,
    DistanceEstimate? distance,
    TiltEstimate? tilt,
    GpsVerificationResult? gps,
    CropSegmentationResult? segmentation,
  }) {
    _currentState = ValidationState(
      imageQuality: quality ?? _currentState.imageQuality,
      distance: distance ?? _currentState.distance,
      tilt: tilt ?? _currentState.tilt,
      gps: gps ?? _currentState.gps,
      segmentation: segmentation ?? _currentState.segmentation,
      isStable: _stabilityTracker.isStable,
      timestamp: DateTime.now(),
    );
    
    onValidationUpdate?.call(_currentState);
  }

  void dispose() {
    stop();
    _qualityAnalyzer.dispose();
  }
}

/// Validation result with capture decision
class CaptureValidationResult {
  final bool canCapture;
  final double score;
  final List<String> blockers;
  final List<String> warnings;
  final ValidationState state;

  const CaptureValidationResult({
    required this.canCapture,
    required this.score,
    required this.blockers,
    required this.warnings,
    required this.state,
  });

  factory CaptureValidationResult.fromEngine(ValidationEngine engine) {
    return CaptureValidationResult(
      canCapture: engine.canCapture(),
      score: engine.getValidationScore(),
      blockers: engine.getCaptureBlockers(),
      warnings: engine.currentState.imageQuality?.warnings ?? [],
      state: engine.currentState,
    );
  }
}
