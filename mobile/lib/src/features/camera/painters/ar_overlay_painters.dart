import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ar_camera_models.dart';

/// Main AR overlay painter that combines all visual elements
class AROverlayPainter extends CustomPainter {
  final ValidationState? validationState;
  final CaptureTask? currentTask;
  final Size previewSize;
  final bool showBoundingBox;
  final bool showTiltIndicator;
  final bool showQualityIndicator;
  final bool showGpsIndicator;
  final bool showCropMask;
  final Animation<double>? pulseAnimation;

  AROverlayPainter({
    this.validationState,
    this.currentTask,
    required this.previewSize,
    this.showBoundingBox = true,
    this.showTiltIndicator = true,
    this.showQualityIndicator = true,
    this.showGpsIndicator = true,
    this.showCropMask = true,
    this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    if (showBoundingBox) {
      _drawBoundingBox(canvas, size);
    }
    if (showTiltIndicator) {
      _drawTiltIndicator(canvas, size);
    }
    // Crop mask disabled - was causing black screen issues
    // if (showCropMask && validationState?.segmentation != null) {
    //   _drawCropMask(canvas, size);
    // }
  }

  void _drawBoundingBox(Canvas canvas, Size size) {
    final distanceStatus = validationState?.distance?.status ?? DistanceStatus.optimal;
    
    Color boxColor;
    switch (distanceStatus) {
      case DistanceStatus.tooClose:
        boxColor = ARColors.error;
        break;
      case DistanceStatus.tooFar:
        boxColor = ARColors.warning;
        break;
      case DistanceStatus.optimal:
        boxColor = ARColors.valid;
        break;
    }

    // Pulse effect
    final pulseValue = pulseAnimation?.value ?? 1.0;
    final strokeWidth = 3.0 + (pulseValue * 1.0);

    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw rounded rectangle bounding box
    final margin = size.width * 0.1;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2),
      const Radius.circular(20),
    );

    // Draw corner brackets only (cleaner look)
    final cornerLength = 40.0;
    final path = Path();

    // Top-left corner
    path.moveTo(rect.left + cornerLength, rect.top);
    path.lineTo(rect.left + rect.tlRadiusX, rect.top);
    path.arcToPoint(
      Offset(rect.left, rect.top + rect.tlRadiusY),
      radius: rect.tlRadius,
    );
    path.lineTo(rect.left, rect.top + cornerLength);

    // Top-right corner
    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right - rect.trRadiusX, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + rect.trRadiusY),
      radius: rect.trRadius,
      clockwise: true,
    );
    path.lineTo(rect.right, rect.top + cornerLength);

    // Bottom-left corner
    path.moveTo(rect.left, rect.bottom - cornerLength);
    path.lineTo(rect.left, rect.bottom - rect.blRadiusY);
    path.arcToPoint(
      Offset(rect.left + rect.blRadiusX, rect.bottom),
      radius: rect.blRadius,
    );
    path.lineTo(rect.left + cornerLength, rect.bottom);

    // Bottom-right corner
    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom - rect.brRadiusY);
    path.arcToPoint(
      Offset(rect.right - rect.brRadiusX, rect.bottom),
      radius: rect.brRadius,
      clockwise: true,
    );
    path.lineTo(rect.right - cornerLength, rect.bottom);

    canvas.drawPath(path, paint);

    // Draw distance arrows if needed
    if (distanceStatus == DistanceStatus.tooClose) {
      _drawDistanceArrows(canvas, size, outward: true);
    } else if (distanceStatus == DistanceStatus.tooFar) {
      _drawDistanceArrows(canvas, size, outward: false);
    }
  }

  void _drawDistanceArrows(Canvas canvas, Size size, {required bool outward}) {
    final paint = Paint()
      ..color = outward ? ARColors.error : ARColors.warning
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final arrowSize = 20.0;
    final distance = size.width * 0.35;

    // Draw 4 arrows pointing inward or outward
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 2);
      
      final arrowTip = Offset(outward ? distance + arrowSize : distance - arrowSize, 0);
      final arrowBase1 = Offset(outward ? distance : distance, -arrowSize / 2);
      final arrowBase2 = Offset(outward ? distance : distance, arrowSize / 2);
      
      final path = Path()
        ..moveTo(arrowTip.dx, arrowTip.dy)
        ..lineTo(arrowBase1.dx, arrowBase1.dy)
        ..lineTo(arrowBase2.dx, arrowBase2.dy)
        ..close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawTiltIndicator(Canvas canvas, Size size) {
    final tilt = validationState?.tilt;
    if (tilt == null) return;

    final center = Offset(size.width / 2, size.height - 80);
    final radius = 30.0;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 5, bgPaint);

    // Tilt indicator
    Color indicatorColor;
    switch (tilt.status) {
      case TiltStatus.level:
        indicatorColor = ARColors.valid;
        break;
      case TiltStatus.slightlyTilted:
        indicatorColor = ARColors.warning;
        break;
      case TiltStatus.tilted:
        indicatorColor = ARColors.error;
        break;
    }

    // Outer ring
    final ringPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    // Bubble position based on tilt
    final maxOffset = radius - 8;
    
    // Safe handling of tilt values with NaN/infinity checks
    double safeRoll = tilt.rollDegrees.isNaN || tilt.rollDegrees.isInfinite ? 0.0 : tilt.rollDegrees;
    double safePitch = tilt.pitchDegrees.isNaN || tilt.pitchDegrees.isInfinite ? 0.0 : tilt.pitchDegrees;
    
    final bubbleX = (safeRoll / 45.0).clamp(-1.0, 1.0) * maxOffset;
    final bubbleY = (safePitch / 45.0).clamp(-1.0, 1.0) * maxOffset;
    
    final bubblePaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + bubbleX, center.dy + bubbleY),
      8,
      bubblePaint,
    );

    // Center crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      crossPaint,
    );
  }

  void _drawCropMask(Canvas canvas, Size size) {
    final segmentation = validationState?.segmentation;
    // Only draw mask when crop is detected with good coverage
    if (segmentation == null || !segmentation.cropDetected) return;
    if (segmentation.coverage < 0.1) return; // Skip if coverage too low
    if (segmentation.status == SegmentationStatus.noCropDetected) return;

    final boundingBox = segmentation.cropBoundingBox;
    if (boundingBox == null) return;
    
    // Validate bounding box is reasonable
    if (boundingBox.width <= 0 || boundingBox.height <= 0) return;

    // Scale bounding box to canvas size with safety checks
    final scaleX = previewSize.width > 0 ? size.width / previewSize.width : 1.0;
    final scaleY = previewSize.height > 0 ? size.height / previewSize.height : 1.0;
    
    // Ensure scales are finite and reasonable
    if (!scaleX.isFinite || !scaleY.isFinite || scaleX <= 0 || scaleY <= 0) return;
    
    final scaledRect = Rect.fromLTWH(
      (boundingBox.left * scaleX).clamp(0.0, size.width),
      (boundingBox.top * scaleY).clamp(0.0, size.height),
      (boundingBox.width * scaleX).clamp(0.0, size.width),
      (boundingBox.height * scaleY).clamp(0.0, size.height),
    );

    // Only draw light overlay if the scaled rect is reasonable (not covering whole screen)
    final minSize = size.width * 0.1;
    final maxSize = size.width * 0.9;
    if (scaledRect.width < minSize || scaledRect.height < minSize) return;
    if (scaledRect.width > maxSize && scaledRect.height > maxSize) return;
    
    // Draw very light semi-transparent overlay outside crop area
    final overlayPaint = Paint()
      ..color = ARColors.overlay;

    // Only draw if there's meaningful area to highlight
    if (scaledRect.top > 10) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, scaledRect.top),
        overlayPaint,
      );
    }
    if (size.height - scaledRect.bottom > 10) {
      canvas.drawRect(
        Rect.fromLTWH(0, scaledRect.bottom, size.width, size.height - scaledRect.bottom),
        overlayPaint,
      );
    }
    if (scaledRect.left > 10) {
      canvas.drawRect(
        Rect.fromLTWH(0, scaledRect.top, scaledRect.left, scaledRect.height),
        overlayPaint,
      );
    }
    if (size.width - scaledRect.right > 10) {
      canvas.drawRect(
        Rect.fromLTWH(scaledRect.right, scaledRect.top, size.width - scaledRect.right, scaledRect.height),
        overlayPaint,
      );
    }

    // Draw crop boundary
    Color borderColor;
    switch (segmentation.status) {
      case SegmentationStatus.goodCoverage:
        borderColor = ARColors.valid;
        break;
      case SegmentationStatus.partialCoverage:
        borderColor = ARColors.warning;
        break;
      default:
        borderColor = ARColors.neutral;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(scaledRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant AROverlayPainter oldDelegate) {
    return validationState != oldDelegate.validationState ||
           currentTask != oldDelegate.currentTask ||
           pulseAnimation?.value != oldDelegate.pulseAnimation?.value;
  }
}

/// Painter for ghost frame guidance (multi-angle capture)
class GhostFramePainter extends CustomPainter {
  final CaptureTask? task;
  final double opacity;
  final ui.Image? ghostImage;

  GhostFramePainter({
    this.task,
    this.opacity = 0.3,
    this.ghostImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (task == null) return;

    // Draw ghost silhouette based on task type
    switch (task!.type) {
      case CaptureTaskType.topView:
        _drawTopViewGuide(canvas, size);
        break;
      case CaptureTaskType.sideView:
        _drawSideViewGuide(canvas, size);
        break;
      case CaptureTaskType.closeUp:
        _drawCloseUpGuide(canvas, size);
        break;
      case CaptureTaskType.wideAngle:
        _drawWideAngleGuide(canvas, size);
        break;
      case CaptureTaskType.stageSpecific:
        _drawGenericGuide(canvas, size);
        break;
    }
  }

  void _drawTopViewGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw circular guide for top-down view
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    canvas.drawCircle(center, radius, paint);

    // Draw crosshair
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );

    // Draw "look down" arrow
    _drawArrowDown(canvas, size);
  }

  void _drawSideViewGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw plant silhouette for side view
    final centerX = size.width / 2;
    final bottom = size.height * 0.7;
    final top = size.height * 0.3;

    // Stem
    canvas.drawLine(
      Offset(centerX, bottom),
      Offset(centerX, top),
      paint,
    );

    // Leaves (simplified)
    final path = Path();
    // Left leaf
    path.moveTo(centerX, top + (bottom - top) * 0.3);
    path.quadraticBezierTo(
      centerX - 50, top + (bottom - top) * 0.2,
      centerX - 30, top + (bottom - top) * 0.1,
    );
    // Right leaf
    path.moveTo(centerX, top + (bottom - top) * 0.4);
    path.quadraticBezierTo(
      centerX + 50, top + (bottom - top) * 0.3,
      centerX + 35, top + (bottom - top) * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  void _drawCloseUpGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw magnifying circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25;

    canvas.drawCircle(center, radius, paint);

    // Inner focus rings
    canvas.drawCircle(center, radius * 0.7, paint..strokeWidth = 1);
    canvas.drawCircle(center, radius * 0.4, paint..strokeWidth = 1);
  }

  void _drawWideAngleGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw field/horizon line
    final horizonY = size.height * 0.6;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      paint,
    );

    // Draw perspective lines
    final vanishingPoint = Offset(size.width / 2, horizonY);
    
    canvas.drawLine(
      Offset(0, size.height),
      vanishingPoint,
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      vanishingPoint,
      paint,
    );
  }

  void _drawGenericGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Simple rule of thirds grid
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawArrowDown(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ARColors.ghost
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final arrowY = size.height * 0.15;
    
    final path = Path()
      ..moveTo(centerX, arrowY + 20)
      ..lineTo(centerX - 15, arrowY)
      ..lineTo(centerX - 5, arrowY)
      ..lineTo(centerX - 5, arrowY - 20)
      ..lineTo(centerX + 5, arrowY - 20)
      ..lineTo(centerX + 5, arrowY)
      ..lineTo(centerX + 15, arrowY)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GhostFramePainter oldDelegate) {
    return task != oldDelegate.task || opacity != oldDelegate.opacity;
  }
}

/// Painter for stability/level meter indicator
class StabilityIndicatorPainter extends CustomPainter {
  final double tiltX;  // Roll (left/right)
  final double tiltY;  // Pitch (forward/back)
  final bool isStable;

  StabilityIndicatorPainter({
    required this.tiltX,
    required this.tiltY,
    required this.isStable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 5;

    // Background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius + 3, bgPaint);

    // Outer ring
    final ringColor = isStable ? ARColors.valid : ARColors.warning;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, centerY), radius, ringPaint);

    // Crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(centerX - radius + 5, centerY),
      Offset(centerX + radius - 5, centerY),
      crossPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - radius + 5),
      Offset(centerX, centerY + radius - 5),
      crossPaint,
    );

    // Inner circles (tolerance zones)
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.3, innerPaint);
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.6, innerPaint);

    // Bubble position (inverted for intuitive feel)
    final maxOffset = radius - 10;
    final bubbleX = (-tiltX / 10.0).clamp(-1.0, 1.0) * maxOffset;
    final bubbleY = (-tiltY / 10.0).clamp(-1.0, 1.0) * maxOffset;

    // Bubble
    final bubblePaint = Paint()
      ..color = isStable ? ARColors.valid : ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX + bubbleX, centerY + bubbleY),
      10,
      bubblePaint,
    );

    // Bubble highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX + bubbleX - 3, centerY + bubbleY - 3),
      3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StabilityIndicatorPainter oldDelegate) {
    return tiltX != oldDelegate.tiltX ||
           tiltY != oldDelegate.tiltY ||
           isStable != oldDelegate.isStable;
  }
}

/// Painter for GPS verification overlay with mini-map
class GpsOverlayPainter extends CustomPainter {
  final GpsVerificationResult? gpsResult;
  final List<Offset>? farmBoundary;  // Polygon points
  final Offset? currentPosition;     // Current location in local coords
  final double scale;

  GpsOverlayPainter({
    this.gpsResult,
    this.farmBoundary,
    this.currentPosition,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gpsResult == null) return;

    // Draw GPS status indicator
    _drawGpsStatusIndicator(canvas, size);

    // Draw mini-map if boundary available
    if (farmBoundary != null && farmBoundary!.isNotEmpty) {
      _drawMiniMap(canvas, size);
    }
  }

  void _drawGpsStatusIndicator(Canvas canvas, Size size) {
    final status = gpsResult!.status;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case GpsStatus.noFix:
        statusColor = ARColors.warning;
        break;
      case GpsStatus.lowAccuracy:
        statusColor = ARColors.warning;
        break;
      case GpsStatus.insideBoundary:
        statusColor = ARColors.valid;
        break;
      case GpsStatus.outsideBoundary:
        statusColor = ARColors.error;
        break;
    }

    // Draw status dot
    final dotPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width - 20, 20),
      8,
      dotPaint,
    );

    // Draw pulse ring for "acquiring" status
    if (status == GpsStatus.noFix) {
      final ringPaint = Paint()
        ..color = statusColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(size.width - 20, 20),
        12,
        ringPaint,
      );
    }
  }

  void _drawMiniMap(Canvas canvas, Size size) {
    if (farmBoundary == null || farmBoundary!.isEmpty) return;

    // Mini-map in bottom-right corner
    final mapSize = 80.0;
    final mapRect = Rect.fromLTWH(
      size.width - mapSize - 10,
      size.height - mapSize - 60,
      mapSize,
      mapSize,
    );

    // Background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(mapRect, const Radius.circular(8)),
      bgPaint,
    );

    // Calculate bounds of farm polygon
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    
    for (final point in farmBoundary!) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    // Scale and translate to fit in mini-map
    final scaleX = (mapSize - 20) / (maxX - minX);
    final scaleY = (mapSize - 20) / (maxY - minY);
    final mapScale = math.min(scaleX, scaleY);

    // Draw farm boundary
    Color boundaryColor = gpsResult!.isInsideFarmBoundary 
        ? ARColors.valid 
        : ARColors.error;
    
    final boundaryPaint = Paint()
      ..color = boundaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool first = true;
    for (final point in farmBoundary!) {
      final x = mapRect.left + 10 + (point.dx - minX) * mapScale;
      final y = mapRect.top + 10 + (point.dy - minY) * mapScale;
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, boundaryPaint);

    // Draw current position
    if (currentPosition != null) {
      final posX = mapRect.left + 10 + (currentPosition!.dx - minX) * mapScale;
      final posY = mapRect.top + 10 + (currentPosition!.dy - minY) * mapScale;

      // Position dot
      final posPaint = Paint()
        ..color = ARColors.neutral
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(posX, posY), 5, posPaint);

      // Accuracy circle
      final accuracyPaint = Paint()
        ..color = ARColors.neutral.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(posX, posY),
        (gpsResult!.accuracy * mapScale).clamp(5, 20),
        accuracyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GpsOverlayPainter oldDelegate) {
    return gpsResult != oldDelegate.gpsResult ||
           currentPosition != oldDelegate.currentPosition;
  }
}

/// Painter for quality warning banner
class QualityWarningPainter extends CustomPainter {
  final ImageQualityResult? qualityResult;
  final Animation<double>? animation;

  QualityWarningPainter({
    this.qualityResult,
    this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (qualityResult == null || qualityResult!.warnings.isEmpty) return;

    final warning = qualityResult!.warnings.first;
    
    // Determine color based on status
    Color bgColor;
    switch (qualityResult!.overallStatus) {
      case QualityStatus.good:
        return; // No warning needed
      case QualityStatus.warning:
        bgColor = ARColors.warning;
        break;
      case QualityStatus.error:
        bgColor = ARColors.error;
        break;
    }

    // Animate opacity
    final opacity = animation?.value ?? 1.0;

    // Draw warning banner at top
    final bannerHeight = 40.0;
    final bannerPaint = Paint()
      ..color = bgColor.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, bannerHeight),
      bannerPaint,
    );

    // Draw warning icon
    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final iconCenter = Offset(25, bannerHeight / 2);
    
    // Warning triangle
    final trianglePath = Path()
      ..moveTo(iconCenter.dx, iconCenter.dy - 10)
      ..lineTo(iconCenter.dx - 10, iconCenter.dy + 8)
      ..lineTo(iconCenter.dx + 10, iconCenter.dy + 8)
      ..close();
    canvas.drawPath(trianglePath, iconPaint);

    // Exclamation mark
    final exclamationPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(iconCenter.dx, iconCenter.dy + 4), 2, exclamationPaint);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(iconCenter.dx, iconCenter.dy - 3), width: 3, height: 8),
      exclamationPaint,
    );

    // Draw warning text (simplified - in real app use TextPainter)
    // Text would be drawn here using TextPainter
  }

  @override
  bool shouldRepaint(covariant QualityWarningPainter oldDelegate) {
    return qualityResult != oldDelegate.qualityResult ||
           animation?.value != oldDelegate.animation?.value;
  }
}
