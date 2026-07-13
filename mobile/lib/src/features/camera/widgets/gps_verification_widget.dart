import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ar_camera_models.dart';

/// GPS verification widget that shows location status and farm boundary
class GpsVerificationWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<Position>? farmBoundary;
  final GpsVerificationResult? gpsResult;
  final VoidCallback? onLocationRefresh;
  final bool compact;

  const GpsVerificationWidget({
    super.key,
    this.currentPosition,
    this.farmBoundary,
    this.gpsResult,
    this.onLocationRefresh,
    this.compact = true,
  });

  @override
  State<GpsVerificationWidget> createState() => _GpsVerificationWidgetState();
}

class _GpsVerificationWidgetState extends State<GpsVerificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildExpandedView();
  }

  Widget _buildCompactView() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: GoogleFonts.roboto(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              _buildMiniMap(),
              const SizedBox(height: 8),
              _buildLocationDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Verification',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: GoogleFonts.roboto(
                        color: _getStatusColor(),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onLocationRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: widget.onLocationRefresh,
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMiniMap(),
          const SizedBox(height: 12),
          _buildLocationDetails(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final status = widget.gpsResult?.status ?? GpsStatus.noFix;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double scale = 1.0;
        if (status == GpsStatus.noFix || status == GpsStatus.lowAccuracy) {
          scale = 0.8 + (0.4 * _pulseController.value);
        }
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: status == GpsStatus.noFix
                ? const Icon(Icons.gps_off, color: Colors.white, size: 10)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMiniMap() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: CustomPaint(
        painter: MiniMapPainter(
          currentPosition: widget.currentPosition,
          farmBoundary: widget.farmBoundary,
          isInsideBoundary: widget.gpsResult?.isInsideFarmBoundary ?? false,
          accuracy: widget.gpsResult?.accuracy ?? 0,
        ),
        size: const Size(double.infinity, 120),
      ),
    );
  }

  Widget _buildLocationDetails() {
    final pos = widget.currentPosition;
    final accuracy = widget.gpsResult?.accuracy ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pos != null) ...[
          _buildDetailRow(
            Icons.location_on,
            'Coordinates',
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 4),
          _buildDetailRow(
            Icons.gps_fixed,
            'Accuracy',
            '±${accuracy.toStringAsFixed(1)}m',
            color: accuracy <= 10
                ? ARColors.valid
                : accuracy <= 30
                    ? ARColors.warning
                    : ARColors.error,
          ),
          if (pos.altitude != 0) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              Icons.terrain,
              'Altitude',
              '${pos.altitude.toStringAsFixed(1)}m',
            ),
          ],
        ] else ...[
          _buildDetailRow(
            Icons.location_off,
            'Location',
            'Acquiring GPS signal...',
            color: ARColors.warning,
          ),
        ],
        if (widget.farmBoundary != null && widget.farmBoundary!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildDetailRow(
            Icons.fence,
            'Farm Boundary',
            widget.gpsResult?.isInsideFarmBoundary == true
                ? 'Inside boundary'
                : 'Outside boundary',
            color: widget.gpsResult?.isInsideFarmBoundary == true
                ? ARColors.valid
                : ARColors.error,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white54, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.roboto(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              color: color ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    final status = widget.gpsResult?.status ?? GpsStatus.noFix;
    
    switch (status) {
      case GpsStatus.noFix:
        return ARColors.error;
      case GpsStatus.lowAccuracy:
        return ARColors.warning;
      case GpsStatus.insideBoundary:
        return ARColors.valid;
      case GpsStatus.outsideBoundary:
        return ARColors.error;
    }
  }

  String _getStatusText() {
    final status = widget.gpsResult?.status ?? GpsStatus.noFix;
    
    switch (status) {
      case GpsStatus.noFix:
        return 'Acquiring GPS...';
      case GpsStatus.lowAccuracy:
        return 'Low accuracy';
      case GpsStatus.insideBoundary:
        return 'Location verified';
      case GpsStatus.outsideBoundary:
        return 'Outside farm boundary';
    }
  }
}

/// Custom painter for the mini-map
class MiniMapPainter extends CustomPainter {
  final Position? currentPosition;
  final List<Position>? farmBoundary;
  final bool isInsideBoundary;
  final double accuracy;

  MiniMapPainter({
    this.currentPosition,
    this.farmBoundary,
    required this.isInsideBoundary,
    required this.accuracy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid
    _drawGrid(canvas, size);
    
    if (farmBoundary != null && farmBoundary!.isNotEmpty) {
      _drawFarmBoundary(canvas, size);
    }
    
    if (currentPosition != null) {
      _drawCurrentPosition(canvas, size);
    } else {
      _drawNoSignal(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Draw grid lines
    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawFarmBoundary(Canvas canvas, Size size) {
    if (farmBoundary == null || farmBoundary!.isEmpty) return;

    // Calculate bounds
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;

    for (final pos in farmBoundary!) {
      minLat = math.min(minLat, pos.latitude);
      maxLat = math.max(maxLat, pos.latitude);
      minLng = math.min(minLng, pos.longitude);
      maxLng = math.max(maxLng, pos.longitude);
    }

    // Include current position in bounds if available
    if (currentPosition != null) {
      minLat = math.min(minLat, currentPosition!.latitude);
      maxLat = math.max(maxLat, currentPosition!.latitude);
      minLng = math.min(minLng, currentPosition!.longitude);
      maxLng = math.max(maxLng, currentPosition!.longitude);
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Scale factors
    final padding = 15.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;

    double scaleX = availableWidth / (maxLng - minLng);
    double scaleY = availableHeight / (maxLat - minLat);

    // Use uniform scale
    final scale = math.min(scaleX, scaleY);

    // Transform function
    Offset transform(Position pos) {
      final x = padding + (pos.longitude - minLng) * scale;
      final y = padding + (maxLat - pos.latitude) * scale;
      return Offset(x, y);
    }

    // Draw boundary polygon
    final boundaryPaint = Paint()
      ..color = isInsideBoundary
          ? ARColors.valid.withOpacity(0.3)
          : ARColors.error.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final boundaryStrokePaint = Paint()
      ..color = isInsideBoundary ? ARColors.valid : ARColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool first = true;
    for (final pos in farmBoundary!) {
      final point = transform(pos);
      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, boundaryPaint);
    canvas.drawPath(path, boundaryStrokePaint);

    // Draw current position
    if (currentPosition != null) {
      final currentPoint = transform(currentPosition!);
      
      // Accuracy circle
      final accuracyRadius = (accuracy / 10) * scale;
      final accuracyPaint = Paint()
        ..color = ARColors.neutral.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPoint, accuracyRadius.clamp(5, 30), accuracyPaint);

      // Position dot
      final positionPaint = Paint()
        ..color = ARColors.neutral
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPoint, 6, positionPaint);

      // White border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(currentPoint, 6, borderPaint);
    }
  }

  void _drawCurrentPosition(Canvas canvas, Size size) {
    if (farmBoundary != null && farmBoundary!.isNotEmpty) {
      return; // Already drawn in boundary method
    }

    // Draw centered position when no boundary
    final center = Offset(size.width / 2, size.height / 2);

    // Accuracy circle
    final accuracyPaint = Paint()
      ..color = ARColors.neutral.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 30, accuracyPaint);

    // Position dot
    final positionPaint = Paint()
      ..color = ARColors.valid
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, positionPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, borderPaint);

    // Draw coordinate text
    final textSpan = TextSpan(
      text: '${currentPosition!.latitude.toStringAsFixed(4)}\n${currentPosition!.longitude.toStringAsFixed(4)}',
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 9,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 20),
    );
  }

  void _drawNoSignal(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw GPS off icon representation
    final paint = Paint()
      ..color = ARColors.warning.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw concentric circles (signal searching animation style)
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        i * 15.0,
        paint..color = ARColors.warning.withOpacity(0.5 / i),
      );
    }

    // Draw GPS icon
    final iconPaint = Paint()
      ..color = ARColors.warning
      ..style = PaintingStyle.fill;
    
    final iconPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 4));
    canvas.drawPath(iconPath, iconPaint);

    // Draw "?" text
    final textSpan = TextSpan(
      text: 'Acquiring...',
      style: TextStyle(
        color: ARColors.warning.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 25),
    );
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return currentPosition != oldDelegate.currentPosition ||
           isInsideBoundary != oldDelegate.isInsideBoundary ||
           accuracy != oldDelegate.accuracy;
  }
}

/// Helper service for GPS boundary verification
class GpsBoundaryVerifier {
  /// Check if a point is inside a polygon using ray casting algorithm
  static bool isPointInPolygon(Position point, List<Position> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].longitude > point.longitude) != 
           (polygon[j].longitude > point.longitude)) &&
          (point.latitude <
              (polygon[j].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) +
                  polygon[i].latitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Calculate distance from point to nearest polygon edge
  static double distanceToNearestEdge(Position point, List<Position> polygon) {
    if (polygon.isEmpty) return double.infinity;

    double minDistance = double.infinity;
    
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      
      final distance = _pointToLineDistance(point, p1, p2);
      minDistance = math.min(minDistance, distance);
    }

    return minDistance;
  }

  static double _pointToLineDistance(Position point, Position lineStart, Position lineEnd) {
    // Approximate distance calculation using Haversine
    final a = _haversineDistance(point, lineStart);
    final b = _haversineDistance(point, lineEnd);
    final c = _haversineDistance(lineStart, lineEnd);

    if (c == 0) return a;

    // Calculate perpendicular distance using Heron's formula
    final s = (a + b + c) / 2;
    final area = math.sqrt(math.max(0, s * (s - a) * (s - b) * (s - c)));
    return 2 * area / c;
  }

  static double _haversineDistance(Position p1, Position p2) {
    const R = 6371000; // Earth's radius in meters

    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  /// Calculate polygon area in square meters
  static double calculatePolygonArea(List<Position> polygon) {
    if (polygon.length < 3) return 0;

    double area = 0;
    const R = 6371000; // Earth's radius in meters

    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      
      final lat1 = polygon[i].latitude * math.pi / 180;
      final lat2 = polygon[j].latitude * math.pi / 180;
      final lon1 = polygon[i].longitude * math.pi / 180;
      final lon2 = polygon[j].longitude * math.pi / 180;

      area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }

    area = area.abs() * R * R / 2;
    return area;
  }

  /// Get center point of polygon
  static Position getPolygonCenter(List<Position> polygon) {
    if (polygon.isEmpty) {
      return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    double sumLat = 0;
    double sumLng = 0;

    for (final pos in polygon) {
      sumLat += pos.latitude;
      sumLng += pos.longitude;
    }

    return Position(
      latitude: sumLat / polygon.length,
      longitude: sumLng / polygon.length,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
