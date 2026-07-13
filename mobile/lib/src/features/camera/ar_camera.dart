/// AR Camera Feature - Exports
/// 
/// This barrel file exports all components of the advanced AR camera feature
/// for easy importing throughout the app.
library ar_camera;

// Models
export 'models/ar_camera_models.dart';

// Services
export 'services/image_quality_analyzer.dart';
export 'services/validation_engine.dart';
export 'services/capture_task_manager.dart';
export 'services/crop_segmentation_service.dart';

// Painters
export 'painters/ar_overlay_painters.dart';

// Widgets
export 'widgets/gps_verification_widget.dart';

// Screens - hide GridPainter from enhanced_camera_screen to avoid conflict
export 'presentation/ar_camera_screen.dart';
export 'presentation/enhanced_camera_screen.dart' hide GridPainter;
