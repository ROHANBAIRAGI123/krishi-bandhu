import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';

class EnhancedCameraScreen extends StatefulWidget {
  const EnhancedCameraScreen({super.key});

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  String? _error;
  int _selectedCameraIndex = 0;
  
  // Camera features
  FlashMode _flashMode = FlashMode.auto;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;
  final bool _isRecording = false;
  
  // AR and overlay features
  Position? _currentPosition;
  String? _locationName;
  bool _showGrid = true;
  bool _showAROverlay = true;
  final bool _showLevelIndicator = true;
  
  // Sensors
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  
  // Timer
  Timer? _timer;
  int _timerSeconds = 0;
  bool _isTimerMode = false;
  
  // Animation controllers
  late AnimationController _focusAnimationController;
  late AnimationController _captureAnimationController;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
    _initializeSensors();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initializeSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _tiltX = event.x;
          _tiltY = event.y;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device';
          _isLoading = false;
        });
        return;
      }

      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      setState(() {
        _error = 'Error initializing camera: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;

    if (mounted) {
      // Get zoom levels
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() => _isLoading = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _setupCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }
    
    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  void _onZoomChanged(double scale) {
    if (_controller == null) return;
    
    double zoom = (_currentZoom * scale).clamp(_minZoom, _maxZoom);
    _controller!.setZoomLevel(zoom);
    setState(() => _currentZoom = zoom);
  }

  Future<void> _setFocusPoint(Offset point) async {
    if (_controller == null) return;
    
    try {
      final double x = point.dx.clamp(0.0, 1.0);
      final double y = point.dy.clamp(0.0, 1.0);
      
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
      
      setState(() => _focusPoint = point);
      _focusAnimationController.forward(from: 0.0);
    } catch (e) {
      debugPrint('Focus error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_isTimerMode) {
      _startTimer();
      return;
    }
    
    await _captureImage();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 3);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 1) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
        _captureImage();
        setState(() => _timerSeconds = 0);
      }
    });
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      
      // Capture animation
      _captureAnimationController.forward(from: 0.0).then((_) {
        _captureAnimationController.reverse();
      });

      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await File(image.path).copy(imagePath);

      if (mounted) {
        context.push('/camera/preview', extra: imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    _timer?.cancel();
    _focusAnimationController.dispose();
    _captureAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Widget _buildFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return const Icon(Icons.flash_off);
      case FlashMode.auto:
        return const Icon(Icons.flash_auto);
      case FlashMode.always:
        return const Icon(Icons.flash_on);
      case FlashMode.torch:
        return const Icon(Icons.flashlight_on);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          backgroundColor: Colors.black,
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('camera', 'initializing_camera', lang),
                        style: GoogleFonts.roboto(color: Colors.white),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: GoogleFonts.roboto(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.pop(),
                            child: Text(AppStrings.get('camera', 'go_back', lang)),
                          ),
                        ],
                      ),
                    )
                  : _buildCameraView(context, lang),
        );
      },
    );
  }

  Widget _buildCameraView(BuildContext context, String lang) {
    return Stack(
                  children: [
                    // Camera Preview
                    Positioned.fill(
                      child: GestureDetector(
                        onScaleUpdate: (details) {
                          _onZoomChanged(details.scale);
                        },
                        onTapUp: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final Offset localPosition = box.globalToLocal(details.globalPosition);
                          final Size size = box.size;
                          final Offset relative = Offset(
                            localPosition.dx / size.width,
                            localPosition.dy / size.height,
                          );
                          _setFocusPoint(relative);
                        },
                        child: CameraPreview(_controller!),
                      ),
                    ),

                    // Capture Flash Animation
                    if (_captureAnimationController.isAnimating)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _captureAnimationController,
                          builder: (context, child) {
                            return Container(
                              color: Colors.white.withOpacity(
                                0.7 * (1 - _captureAnimationController.value),
                              ),
                            );
                          },
                        ),
                      ),

                    // AR Grid Overlay
                    if (_showGrid)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),

                    // AR Information Overlay
                    if (_showAROverlay)
                      Positioned(
                        top: 100,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.crop_square, 
                                    color: Colors.green.shade400, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.get('camera', 'ar_crop_detection', lang),
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_currentPosition != null)
                                _buildARInfoRow(
                                  Icons.location_on,
                                  AppStrings.get('camera', 'location', lang),
                                  '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                  '${_currentPosition!.longitude.toStringAsFixed(4)}',
                                ),
                              _buildARInfoRow(
                                Icons.camera,
                                AppStrings.get('camera', 'resolution', lang),
                                '${_controller!.value.previewSize?.height.toInt()}p',
                              ),
                              _buildARInfoRow(
                                Icons.zoom_in,
                                AppStrings.get('camera', 'zoom', lang),
                                '${_currentZoom.toStringAsFixed(1)}x',
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Level Indicator
                    if (_showLevelIndicator)
                      Positioned(
                        top: MediaQuery.of(context).size.height / 2 - 50,
                        left: 20,
                        child: Container(
                          width: 40,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: CustomPaint(
                            painter: LevelIndicatorPainter(_tiltY),
                          ),
                        ),
                      ),

                    // Focus Point Animation
                    if (_focusPoint != null)
                      Positioned(
                        left: _focusPoint!.dx * MediaQuery.of(context).size.width - 40,
                        top: _focusPoint!.dy * MediaQuery.of(context).size.height - 40,
                        child: AnimatedBuilder(
                          animation: _focusAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (0.5 * _focusAnimationController.value),
                              child: Opacity(
                                opacity: 1.0 - _focusAnimationController.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.yellow,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Timer Countdown
                    if (_timerSeconds > 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Text(
                              '$_timerSeconds',
                              style: GoogleFonts.poppins(
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Top Controls
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => context.pop(),
                            ),
                            
                            Row(
                              children: [
                                // Flash
                                IconButton(
                                  icon: _buildFlashIcon(),
                                  color: Colors.white,
                                  onPressed: _toggleFlash,
                                ),
                                
                                // Timer
                                IconButton(
                                  icon: Icon(
                                    _isTimerMode ? Icons.timer : Icons.timer_off,
                                    color: _isTimerMode ? Colors.yellow : Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() => _isTimerMode = !_isTimerMode);
                                  },
                                ),
                                
                                // Grid
                                IconButton(
                                  icon: Icon(
                                    _showGrid ? Icons.grid_on : Icons.grid_off,
                                    color: _showGrid ? Colors.green : Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() => _showGrid = !_showGrid);
                                  },
                                ),
                                
                                // AR Overlay
                                IconButton(
                                  icon: Icon(
                                    _showAROverlay ? Icons.layers : Icons.layers_outlined,
                                    color: _showAROverlay ? Colors.green : Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() => _showAROverlay = !_showAROverlay);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Controls
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                          top: 24,
                          left: 16,
                          right: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Zoom slider
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Row(
                                children: [
                                  Text(
                                    '${_minZoom.toStringAsFixed(1)}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _currentZoom,
                                      min: _minZoom,
                                      max: _maxZoom,
                                      activeColor: Colors.green,
                                      inactiveColor: Colors.white.withOpacity(0.3),
                                      onChanged: (value) {
                                        _controller?.setZoomLevel(value);
                                        setState(() => _currentZoom = value);
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${_maxZoom.toStringAsFixed(1)}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Main controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Gallery
                                IconButton(
                                  icon: const Icon(Icons.photo_library, size: 32),
                                  color: Colors.white,
                                  onPressed: () {
                                    // TODO: Open gallery
                                  },
                                ),
                                
                                // Capture button
                                GestureDetector(
                                  onTap: _takePicture,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isTimerMode ? Colors.yellow : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Switch camera
                                IconButton(
                                  icon: const Icon(Icons.flip_camera_ios, size: 32),
                                  color: Colors.white,
                                  onPressed: _switchCamera,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
  }

  Widget _buildARInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade400, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Grid Painter for AR overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Level Indicator Painter
class LevelIndicatorPainter extends CustomPainter {
  final double tilt;

  LevelIndicatorPainter(this.tilt);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getLevelColor()
      ..style = PaintingStyle.fill;

    // Calculate bubble position based on tilt
    final double bubbleY = (size.height / 2) + (tilt * 5).clamp(-30.0, 30.0);
    
    canvas.drawCircle(
      Offset(size.width / 2, bubbleY),
      8,
      paint,
    );

    // Center line
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );
  }

  Color _getLevelColor() {
    if (tilt.abs() < 1.0) {
      return Colors.green;
    } else if (tilt.abs() < 3.0) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant LevelIndicatorPainter oldDelegate) {
    return oldDelegate.tilt != tilt;
  }
}
