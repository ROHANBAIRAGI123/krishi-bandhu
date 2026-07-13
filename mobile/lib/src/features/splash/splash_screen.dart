import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../widgets/app_icon.dart';
import '../../widgets/shimmer_loading.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    // Scale animation for icon
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Rotate animation for loader
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  Future<void> _startInitialization() async {
    try {
      // Wait for initialization to complete
      await widget.onInitializationComplete();
      
      // Add minimum splash duration for smooth UX
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Navigation is handled by parent - no action needed here
      if (kDebugMode) debugPrint('✅ Splash initialization complete');
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      // Still proceed after error
      await Future.delayed(const Duration(milliseconds: 2000));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade700,
              Colors.green.shade500,
              Colors.lightGreen.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated App Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Hero(
                    tag: 'app_icon',
                    child: AppIcon(
                      size: 140,
                      showLabel: true,
                      backgroundColor: Colors.white,
                      iconColor: Colors.green.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // App Name with Fade Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Krishi Bandhu - PMFBY',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'कृषि बंधु',
                        style: GoogleFonts.notoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PMFBY Crop Insurance',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Animated loading dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PulsingDot(
                            size: 8,
                            color: Colors.white,
                            duration: const Duration(milliseconds: 800),
                          ),
                          const SizedBox(width: 8),
                          PulsingDot(
                            size: 8,
                            color: Colors.white,
                            duration: const Duration(milliseconds: 800),
                          ),
                          const SizedBox(width: 8),
                          PulsingDot(
                            size: 8,
                            color: Colors.white,
                            duration: const Duration(milliseconds: 800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShimmerLoading(
                        child: Text(
                          'Loading...',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Version info
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'v1.0.0',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
