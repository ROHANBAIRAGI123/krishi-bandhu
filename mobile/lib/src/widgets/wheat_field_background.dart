import 'package:flutter/material.dart';

/// Reusable Wheat Field Background Widget
/// गेहूं के खेत की पृष्ठभूमि - हर स्क्रीन के लिए
class WheatFieldBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? overlayColors;
  final double overlayOpacity;

  const WheatFieldBackground({
    super.key,
    required this.child,
    this.overlayColors,
    this.overlayOpacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // PMFBY Background Image - Full Screen Consistent
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/OVERALLBACKGROUND.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            repeat: ImageRepeat.noRepeat,
            errorBuilder: (context, error, stackTrace) {
              // Try alternate background
              return Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                repeat: ImageRepeat.noRepeat,
                errorBuilder: (ctx, err, stack) {
                  // Final fallback gradient
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade50,
                          Colors.amber.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Transparent Gradient Overlay - PMFBY Style
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: overlayColors ?? [
                  Colors.white.withOpacity(0.80),  // Top - more opaque
                  Colors.white.withOpacity(0.65),  // Upper-mid - lighter
                  Colors.white.withOpacity(0.70),  // Lower-mid - balanced
                  Colors.white.withOpacity(0.80),  // Bottom - more opaque
                ],
              ),
            ),
          ),
        ),
        
        // Content - Slides over background
        child,
      ],
    );
  }
}

/// Transparent Card Widget for PMFBY Background
/// पारदर्शी कार्ड विजेट - PMFBY स्टाइल
class TransparentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final Color? borderColor;
  final double borderRadius;
  final bool showShadow;

  const TransparentCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity = 0.88,  // Slightly more opaque for better readability
    this.borderColor,
    this.borderRadius = 20,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.green.shade300.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
