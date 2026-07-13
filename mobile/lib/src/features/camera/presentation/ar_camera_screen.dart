import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../services/local_storage_service.dart';
import '../models/ar_camera_models.dart';
import '../painters/ar_overlay_painters.dart';
import '../services/validation_engine.dart';
import '../services/capture_task_manager.dart';
import '../services/image_quality_analyzer.dart';

/// Advanced AR Camera Screen with real-time validation and guidance
class ARCameraScreen extends StatefulWidget {
  final String? purpose;
  final List<CaptureTask>? customTasks;
  final bool multiAngleMode;
  final String? farmPlotId;
  final List<Position>? farmBoundary;

  const ARCameraScreen({
    super.key,
    this.purpose,
    this.customTasks,
    this.multiAngleMode = false,
    this.farmPlotId,
    this.farmBoundary,
  });

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Camera
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  String? _error;
  int _selectedCameraIndex = 0;
  bool _isProcessingFrame = false;
  int _lastFrameProcessed = 0;

  // Camera features
  FlashMode _flashMode = FlashMode.auto;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;

  // Validation & AR
  late ValidationEngine _validationEngine;
  late CaptureTaskManager _taskManager;
  ValidationState _currentValidation = ValidationState(timestamp: DateTime.now());
  bool _showAROverlay = true;
  bool _showGrid = true;
  bool _showTiltIndicator = true;
  bool _showQualityIndicator = true;
  bool _showGpsIndicator = true;
  bool _showGhostFrame = true;

  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _captureAnimationController;
  late AnimationController _warningAnimationController;
  late AnimationController _taskTransitionController;

  // Focus
  Offset? _focusPoint;
  late AnimationController _focusAnimationController;

  // State
  bool _isCapturing = false;
  bool _captureEnabled = false;
  List<String> _warningMessages = [];

  // GPS
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeValidation();
    _initializeCamera();
    _initializeGps();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _warningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _taskTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeValidation() {
    _validationEngine = ValidationEngine(
      thresholds: ValidationThresholds.standard,
      onValidationUpdate: (state) {
        if (mounted) {
          setState(() {
            _currentValidation = state;
            _captureEnabled = _validationEngine.canCapture();
            _warningMessages = _validationEngine.getWarningMessages();
          });
        }
      },
    );

    // Initialize task manager
    final tasks = widget.customTasks ?? 
        (widget.multiAngleMode 
            ? CaptureTask.standardMultiAngleTasks 
            : CaptureTaskFactory.createMinimalTasks());

    _taskManager = CaptureTaskManager(
      tasks: tasks,
      onTaskChange: (index, task) {
        _taskTransitionController.forward(from: 0.0);
        _showTaskInstruction(task.task);
      },
      onAllTasksComplete: (completedTasks) {
        _onAllTasksComplete();
      },
    );

    // Set farm boundary if provided
    if (widget.farmBoundary != null) {
      _validationEngine.setFarmBoundary(widget.farmBoundary!);
    }
  }

  Future<void> _initializeGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Initial position
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        // Start listening for updates
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          _currentPosition = position;
          _validationEngine.updateGpsPosition(position);
        });

        if (_currentPosition != null) {
          _validationEngine.updateGpsPosition(_currentPosition!);
        }
      }
    } catch (e) {
      debugPrint('GPS initialization error: $e');
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
      try {
        await _controller!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
      try {
        await _controller!.dispose();
      } catch (e) {
        debugPrint('Error disposing controller: $e');
      }
    }

    try {
      _controller = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.medium, // Reduced from high to prevent issues
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (!mounted) return;

      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;

      // Add delay before starting image stream to prevent black screen
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted || _controller == null || !_controller!.value.isInitialized) return;

      // Start image stream for real-time analysis with retry
      try {
        await _controller!.startImageStream(_processFrame);
      } catch (e) {
        debugPrint('Error starting image stream: $e');
        // Retry once after delay
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && _controller != null && _controller!.value.isInitialized) {
          try {
            await _controller!.startImageStream(_processFrame);
          } catch (e2) {
            debugPrint('Failed to start stream after retry: $e2');
          }
        }
      }

      // Start validation engine
      await _validationEngine.start();

      // Start task manager session
      _taskManager.startSession();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize camera: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _processFrame(CameraImage image) {
    // Skip if already processing or widget not mounted
    if (_isProcessingFrame || !mounted) return;
    _isProcessingFrame = true;

    // Process frame in validation engine with timeout protection
    Future.delayed(Duration.zero, () async {
      try {
        await _validationEngine.processFrame(image).timeout(
          const Duration(milliseconds: 200),
          onTimeout: () {
            // Skip this frame if processing takes too long
            debugPrint('Frame processing timeout - skipping frame');
          },
        );
      } catch (e) {
        debugPrint('Frame processing error: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  void _showTaskInstruction(CaptureTask task) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    task.instruction,
                    style: GoogleFonts.roboto(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: ARColors.neutral,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onAllTasksComplete() {
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final summary = _taskManager.getSummary();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ARColors.valid.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: ARColors.valid, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Photos Captured!', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have captured ${summary.completedTasks} photos successfully.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(Icons.photo_library, 'Photos taken', '${summary.completedTasks}'),
                  if (summary.skippedTasks > 0)
                    _buildSummaryRow(Icons.skip_next, 'Skipped', '${summary.skippedTasks}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What would you like to do next?',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _addMorePhotos();
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Take More'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishAndUpload(summary);
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload & Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ARColors.valid,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCapturedPreview() {
    final capturedImages = _taskManager.getCompletedImagePaths();
    if (capturedImages.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Captured Photos (${capturedImages.length})',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: capturedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ARColors.valid),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(
                        File(capturedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Take More'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCompletionDialog();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ARColors.valid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addMorePhotos() {
    // Reset tasks for more captures
    _taskManager.reset();
    _taskManager.startSession();
    setState(() {});
  }

  void _finishAndUpload(CaptureSessionSummary summary) async {
    // Save all captured images to local storage for syncing
    if (summary.capturedImages.isNotEmpty) {
      try {
        final localStorage = LocalStorageService();
        
        // Save each captured image to pending uploads
        for (final imagePath in summary.capturedImages) {
          final taskItem = _taskManager.tasks.firstWhere(
            (t) => t.capturedImagePath == imagePath,
            orElse: () => _taskManager.tasks.first,
          );
          
          final metadata = taskItem.metadata ?? {};
          
          await localStorage.savePendingUpload(
            PendingUpload(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              imagePath: imagePath,
              cropType: widget.purpose ?? 'general',
              description: taskItem.task.instruction,
              latitude: metadata['latitude'] as double?,
              longitude: metadata['longitude'] as double?,
              capturedAt: taskItem.capturedAt ?? DateTime.now(),
              status: SyncStatus.pending,
            ),
          );
        }
        
        debugPrint('Saved ${summary.capturedImages.length} images to local storage');
      } catch (e) {
        debugPrint('Error saving to local storage: $e');
      }
      
      context.go('/dashboard');
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${summary.completedTasks} photos saved locally. They will sync when online.',
                ),
              ),
            ],
          ),
          backgroundColor: ARColors.valid,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Could navigate to upload queue screen
            },
          ),
        ),
      );
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing || !_captureEnabled) return;

    setState(() => _isCapturing = true);

    try {
      // Stop image stream temporarily
      try {
        await _controller?.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping stream: $e');
      }

      // Capture animation
      _captureAnimationController.forward(from: 0.0).then((_) {
        _captureAnimationController.reverse();
      });

      await _initializeControllerFuture;

      // Save to app documents directory (permanent storage)
      final directory = await getApplicationDocumentsDirectory();
      final capturesDir = Directory(path.join(directory.path, 'captures'));
      if (!await capturesDir.exists()) {
        await capturesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final taskId = _taskManager.currentTask?.task.id ?? 'unknown';
      final imagePath = path.join(
        capturesDir.path,
        'capture_${taskId}_${timestamp}.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await File(image.path).copy(imagePath);
      
      // Delete temporary file
      try {
        await File(image.path).delete();
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }

      debugPrint('Image saved to: $imagePath');

      // Analyze captured image for blur AFTER capture
      final imageAnalyzer = ImageQualityAnalyzer();
      final qualityResult = await imageAnalyzer.analyzeImageFile(imagePath);
      
      // Show warning if image is blurry
      if (qualityResult.isBlurry && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: Image may be blurry (score: ${qualityResult.blurScore.toInt()}). Consider retaking for better quality.',
                  ),
                ),
              ],
            ),
            backgroundColor: ARColors.warning,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      // Complete current task
      _taskManager.completeCurrentTask(
        imagePath: imagePath,
        validationState: _currentValidation,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
          'zoom': _currentZoom,
          'flashMode': _flashMode.toString(),
          'validationScore': _validationEngine.getValidationScore(),
        },
      );

      // Restart image stream if more tasks remain
      if (!_taskManager.allTasksCompleted) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && _controller != null && _controller!.value.isInitialized) {
            await _controller!.startImageStream(_processFrame);
          }
        } catch (e) {
          debugPrint('Error restarting stream: $e');
        }
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: ARColors.error,
          ),
        );
      }

      // Restart image stream on error
      try {
        if (mounted && _controller != null && _controller!.value.isInitialized) {
          await _controller!.startImageStream(_processFrame);
        }
      } catch (e) {
        debugPrint('Error restarting stream after error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() => _isLoading = true);
    await _controller?.stopImageStream();
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop image stream first
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        _controller!.stopImageStream().catchError((e) {
          debugPrint('Error stopping stream in dispose: $e');
        });
      } catch (e) {
        debugPrint('Error in dispose stream: $e');
      }
    }
    
    _controller?.dispose();
    _validationEngine.dispose();
    _taskManager.dispose();
    _positionSubscription?.cancel();
    _pulseAnimationController.dispose();
    _captureAnimationController.dispose();
    _warningAnimationController.dispose();
    _taskTransitionController.dispose();
    _focusAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Pause camera operations
      _validationEngine.stop();
      if (controller != null && controller.value.isInitialized) {
        try {
          controller.stopImageStream().catchError((e) {
            debugPrint('Error stopping stream on pause: $e');
          });
        } catch (e) {
          debugPrint('Error in pause: $e');
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume camera operations
      if (controller != null && controller.value.isInitialized) {
        try {
          controller.startImageStream(_processFrame).then((_) {
            _validationEngine.start();
          }).catchError((e) {
            debugPrint('Error restarting stream on resume: $e');
            // Try reinitializing if stream restart fails
            _initializeCamera();
          });
        } catch (e) {
          debugPrint('Error in resume: $e');
          _initializeCamera();
        }
      } else {
        // Camera not initialized, reinitialize
        _initializeCamera();
      }
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
              ? _buildLoadingState(lang)
              : _error != null
                  ? _buildErrorState(lang)
                  : _buildCameraView(context, lang),
        );
      },
    );
  }

  Widget _buildLoadingState(String lang) {
    return Center(
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
    );
  }

  Widget _buildErrorState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: ARColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.get('common', 'retry', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ARColors.neutral,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppStrings.get('camera', 'go_back', lang),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(BuildContext context, String lang) {
    // Enhanced safety check to prevent black screens
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.hasError) {
      return _buildLoadingState(lang);
    }

    final size = MediaQuery.of(context).size;
    final previewSize = _controller!.value.previewSize ?? const Size(1920, 1080);

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: GestureDetector(
            onScaleUpdate: (details) => _onZoomChanged(details.scale),
            onTapUp: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPosition = box.globalToLocal(details.globalPosition);
              final Offset relative = Offset(
                localPosition.dx / box.size.width,
                localPosition.dy / box.size.height,
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
                    0.8 * (1 - _captureAnimationController.value),
                  ),
                );
              },
            ),
          ),

        // Grid Overlay
        if (_showGrid)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),

        // AR Overlay - simplified to just show bounding box and tilt
        if (_showAROverlay)
          Positioned.fill(
            child: CustomPaint(
              painter: AROverlayPainter(
                validationState: _currentValidation,
                currentTask: _taskManager.currentTask?.task,
                previewSize: previewSize,
                showBoundingBox: true,
                showTiltIndicator: _showTiltIndicator,
                showQualityIndicator: false, // Disabled to reduce overlays
                showGpsIndicator: false, // Disabled to reduce overlays
                showCropMask: false, // Disabled - was causing black screen
                pulseAnimation: _pulseAnimationController,
              ),
            ),
          ),

        // Ghost Frame - simplified
        if (_showGhostFrame && widget.multiAngleMode && _taskManager.currentTask != null)
          Positioned.fill(
            child: CustomPaint(
              painter: GhostFramePainter(
                task: _taskManager.currentTask?.task,
                opacity: 0.3,
              ),
            ),
          ),

        // Focus Point Animation
        if (_focusPoint != null)
          _buildFocusIndicator(size),

        // Quality Warning Banner
        if (_currentValidation.imageQuality != null && 
            _currentValidation.imageQuality!.overallStatus != QualityStatus.good)
          _buildQualityWarning(lang),

        // Top Controls
        _buildTopControls(context, lang),

        // Task Progress Indicator (multi-angle mode)
        if (widget.multiAngleMode)
          _buildTaskProgress(lang),

        // Stability Indicator
        if (_showTiltIndicator)
          _buildStabilityIndicator(),

        // Bottom Controls
        _buildBottomControls(context, lang),

        // Warning Messages (non-blocking)
        if (_warningMessages.isNotEmpty)
          _buildBlockerIndicator(lang),
      ],
    );
  }

  Widget _buildFocusIndicator(Size size) {
    return Positioned(
      left: _focusPoint!.dx * size.width - 40,
      top: _focusPoint!.dy * size.height - 40,
      child: AnimatedBuilder(
        animation: _focusAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.3 * (1 - _focusAnimationController.value)),
            child: Opacity(
              opacity: 1.0 - (_focusAnimationController.value * 0.7),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ARColors.valid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ARColors.valid,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQualityWarning(String lang) {
    final quality = _currentValidation.imageQuality!;
    String warning = '';
    IconData icon = Icons.warning_amber;

    if (quality.isBlurry) {
      warning = AppStrings.get('camera', 'warning_blurry', lang);
      icon = Icons.blur_on;
    } else if (quality.exposureStatus == ExposureStatus.overexposed) {
      warning = AppStrings.get('camera', 'warning_overexposed', lang);
      icon = Icons.wb_sunny;
    } else if (quality.exposureStatus == ExposureStatus.underexposed) {
      warning = AppStrings.get('camera', 'warning_underexposed', lang);
      icon = Icons.brightness_low;
    } else if (quality.hasBacklight) {
      warning = AppStrings.get('camera', 'warning_backlight', lang);
      icon = Icons.flare;
    }

    if (warning.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _warningAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.7 + (0.3 * _warningAnimationController.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: quality.overallStatus == QualityStatus.error
                    ? ARColors.error.withOpacity(0.9)
                    : ARColors.warning.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      warning,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopControls(BuildContext context, String lang) {
    return Positioned(
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
              onPressed: () => _showExitConfirmation(context, lang),
            ),

            // Title
            if (widget.multiAngleMode && _taskManager.currentTask != null)
              Expanded(
                child: Text(
                  _taskManager.currentTask!.task.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Row(
              children: [
                // Flash
                IconButton(
                  icon: _buildFlashIcon(),
                  color: Colors.white,
                  onPressed: _toggleFlash,
                ),

                // Grid toggle
                IconButton(
                  icon: Icon(
                    _showGrid ? Icons.grid_on : Icons.grid_off,
                    color: _showGrid ? ARColors.valid : Colors.white,
                  ),
                  onPressed: () => setState(() => _showGrid = !_showGrid),
                ),

                // AR toggle
                IconButton(
                  icon: Icon(
                    _showAROverlay ? Icons.layers : Icons.layers_outlined,
                    color: _showAROverlay ? ARColors.valid : Colors.white,
                  ),
                  onPressed: () => setState(() => _showAROverlay = !_showAROverlay),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _buildTaskProgress(String lang) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count and done button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Take ${_taskManager.totalTasks - _taskManager.completedTaskCount} more photos',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_taskManager.completedTaskCount >= 1)
                  TextButton.icon(
                    onPressed: _showCompletionDialog,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Done'),
                    style: TextButton.styleFrom(
                      foregroundColor: ARColors.valid,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Task selector - horizontal scroll
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _taskManager.tasks.length,
                itemBuilder: (context, index) {
                  final taskItem = _taskManager.tasks[index];
                  final isCompleted = taskItem.isComplete;
                  final isActive = index == _taskManager.currentIndex;
                  
                  return GestureDetector(
                    onTap: isCompleted ? null : () => _selectTask(index),
                    child: Container(
                      width: 85,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? ARColors.valid.withOpacity(0.3)
                            : isActive 
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? ARColors.valid : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _getTaskIcon(taskItem.task.type),
                                color: isCompleted ? ARColors.valid : Colors.white,
                                size: 28,
                              ),
                              if (isCompleted)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: ARColors.valid,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            taskItem.task.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              color: isCompleted ? ARColors.valid : Colors.white,
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Current task instruction
            if (_taskManager.currentTask != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ARColors.valid.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ARColors.valid.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ARColors.valid, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _taskManager.currentTask!.task.description,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectTask(int index) {
    _taskManager.goToTask(index);
    setState(() {});
  }

  IconData _getTaskIcon(CaptureTaskType type) {
    switch (type) {
      case CaptureTaskType.topView:
        return Icons.arrow_downward;
      case CaptureTaskType.sideView:
        return Icons.swap_horiz;
      case CaptureTaskType.closeUp:
        return Icons.zoom_in;
      case CaptureTaskType.wideAngle:
        return Icons.panorama_wide_angle;
      case CaptureTaskType.stageSpecific:
        return Icons.spa;
    }
  }

  Widget _buildStabilityIndicator() {
    return Positioned(
      bottom: 200,
      right: 16,
      child: SizedBox(
        width: 60,
        height: 60,
        child: CustomPaint(
          painter: StabilityIndicatorPainter(
            tiltX: _currentValidation.tilt?.rollDegrees ?? 0,
            tiltY: _currentValidation.tilt?.pitchDegrees ?? 0,
            isStable: _currentValidation.isStable,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockerIndicator(String lang) {
    // Show warnings (non-blocking) - distance, tilt, quality info
    if (_warningMessages.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 180,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ARColors.neutral.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _warningMessages.first,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, String lang) {
    final validationScore = _validationEngine.getValidationScore();

    return Positioned(
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
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Validation Score
            _buildValidationScore(validationScore, lang),

            const SizedBox(height: 16),

            // Zoom slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Text(
                    '${_minZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: ARColors.valid,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: ARColors.valid,
                        overlayColor: ARColors.valid.withOpacity(0.2),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _currentZoom,
                        min: _minZoom,
                        max: _maxZoom,
                        onChanged: (value) {
                          _controller?.setZoomLevel(value);
                          setState(() => _currentZoom = value);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${_maxZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery/Preview captured photos
                if (widget.multiAngleMode && _taskManager.completedTaskCount > 0)
                  GestureDetector(
                    onTap: () => _showCapturedPreview(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.black54,
                      ),
                      child: Center(
                        child: Text(
                          '${_taskManager.completedTaskCount}',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),

                // Capture button
                _buildCaptureButton(),

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
    );
  }

  Widget _buildValidationScore(double score, String lang) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = ARColors.valid;
    } else if (score >= 50) {
      scoreColor = ARColors.warning;
    } else {
      scoreColor = ARColors.error;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scoreColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                score >= 80
                    ? Icons.check_circle
                    : score >= 50
                        ? Icons.warning
                        : Icons.error,
                color: scoreColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.get('camera', 'quality', lang)}: ${score.toInt()}%',
                style: GoogleFonts.roboto(
                  color: scoreColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    // Always allow capture - quality issues are just warnings
    final hasWarnings = _validationEngine.hasQualityWarnings();
    final isReady = !_isCapturing;
    final buttonColor = hasWarnings ? ARColors.warning : ARColors.valid;

    return GestureDetector(
      onTap: isReady ? _takePicture : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isReady ? Colors.white : Colors.white38,
            width: 4,
          ),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReady ? buttonColor : Colors.white38,
          ),
          child: _isCapturing
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context, String lang) async {
    if (_taskManager.completedTaskCount == 0) {
      context.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('camera', 'exit_confirmation_title', lang)),
        content: Text(
          AppStrings.get('camera', 'exit_confirmation_message', lang)
              .replaceAll('{count}', '${_taskManager.completedTaskCount}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.get('common', 'cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ARColors.error),
            child: Text(AppStrings.get('common', 'exit', lang)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.pop();
    }
  }
}

// Grid Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Rule of thirds
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center crosshair (subtle)
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const crossSize = 20.0;

    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      centerPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
