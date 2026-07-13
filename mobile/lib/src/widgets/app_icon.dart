import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppIcon extends StatelessWidget {
  final double size;
  final bool showLabel;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppIcon({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final icColor = iconColor ?? Colors.green.shade700;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.21), // ~21% for rounded square
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main Icon - Agriculture/Farming Symbol
          Stack(
            alignment: Alignment.center,
            children: [
              // Sun/Circle background representing growth
              Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: icColor.withOpacity(0.1),
                ),
              ),
              // Main agriculture icon
              Icon(
                Icons.agriculture,
                size: size * 0.5,
                color: icColor,
              ),
            ],
          ),
          
          if (showLabel) ...[
            SizedBox(height: size * 0.05),
            Text(
              'KB',
              style: GoogleFonts.poppins(
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                color: icColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AnimatedAppIcon extends StatefulWidget {
  final double size;
  final bool showLabel;
  final Color? backgroundColor;
  final Color? iconColor;

  const AnimatedAppIcon({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: AppIcon(
        size: widget.size,
        showLabel: widget.showLabel,
        backgroundColor: widget.backgroundColor,
        iconColor: widget.iconColor,
      ),
    );
  }
}
