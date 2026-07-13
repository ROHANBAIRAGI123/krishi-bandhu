import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ar_camera_models.dart';
import 'validation_engine.dart';

/// Status of a capture task
enum TaskStatus {
  pending,
  inProgress,
  completed,
  skipped,
  failed,
}

/// A capture task with its status and captured image
class CaptureTaskItem {
  final CaptureTask task;
  final TaskStatus status;
  final String? capturedImagePath;
  final DateTime? capturedAt;
  final ValidationState? validationState;
  final Map<String, dynamic>? metadata;

  const CaptureTaskItem({
    required this.task,
    this.status = TaskStatus.pending,
    this.capturedImagePath,
    this.capturedAt,
    this.validationState,
    this.metadata,
  });

  CaptureTaskItem copyWith({
    CaptureTask? task,
    TaskStatus? status,
    String? capturedImagePath,
    DateTime? capturedAt,
    ValidationState? validationState,
    Map<String, dynamic>? metadata,
  }) {
    return CaptureTaskItem(
      task: task ?? this.task,
      status: status ?? this.status,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      capturedAt: capturedAt ?? this.capturedAt,
      validationState: validationState ?? this.validationState,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isComplete => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
}

/// Callback types for task events
typedef TaskChangeCallback = void Function(int currentIndex, CaptureTaskItem task);
typedef AllTasksCompleteCallback = void Function(List<CaptureTaskItem> completedTasks);
typedef TaskErrorCallback = void Function(String error);

/// Manager for multi-angle capture workflow
class CaptureTaskManager extends ChangeNotifier {
  final List<CaptureTaskItem> _tasks;
  int _currentIndex = 0;
  bool _isActive = false;
  
  // Callbacks
  TaskChangeCallback? onTaskChange;
  AllTasksCompleteCallback? onAllTasksComplete;
  TaskErrorCallback? onTaskError;
  
  // Timing
  DateTime? _sessionStartTime;
  Duration? _maxSessionDuration;
  Timer? _sessionTimer;

  CaptureTaskManager({
    List<CaptureTask>? tasks,
    this.onTaskChange,
    this.onAllTasksComplete,
    this.onTaskError,
  }) : _tasks = (tasks ?? CaptureTask.standardMultiAngleTasks)
           .map((t) => CaptureTaskItem(task: t))
           .toList();

  // Getters
  List<CaptureTaskItem> get tasks => List.unmodifiable(_tasks);
  int get currentIndex => _currentIndex;
  CaptureTaskItem? get currentTask => 
      _currentIndex < _tasks.length ? _tasks[_currentIndex] : null;
  bool get isActive => _isActive;
  int get totalTasks => _tasks.length;
  int get completedTaskCount => 
      _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get pendingTaskCount => 
      _tasks.where((t) => t.status == TaskStatus.pending).length;
  double get progress => _tasks.isEmpty ? 0 : completedTaskCount / totalTasks;
  bool get allTasksCompleted => completedTaskCount == totalTasks;
  bool get hasMinimumCaptures => completedTaskCount >= 2; // At least 2 captures

  /// Get remaining time in session (if limit set)
  Duration? get remainingTime {
    if (_sessionStartTime == null || _maxSessionDuration == null) return null;
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = _maxSessionDuration! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start a capture session
  void startSession({Duration? maxDuration}) {
    _isActive = true;
    _sessionStartTime = DateTime.now();
    _maxSessionDuration = maxDuration;
    _currentIndex = 0;
    
    // Mark first task as in progress
    if (_tasks.isNotEmpty) {
      _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
        status: TaskStatus.inProgress,
      ));
    }
    
    // Set up session timer if duration is limited
    if (maxDuration != null) {
      _sessionTimer?.cancel();
      _sessionTimer = Timer(maxDuration, () {
        _onSessionTimeout();
      });
    }
    
    notifyListeners();
  }

  /// Stop the capture session
  void stopSession() {
    _isActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    notifyListeners();
  }

  /// Reset all tasks
  void reset() {
    _currentIndex = 0;
    for (int i = 0; i < _tasks.length; i++) {
      _tasks[i] = CaptureTaskItem(task: _tasks[i].task);
    }
    _sessionStartTime = null;
    _isActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    notifyListeners();
  }

  /// Mark current task as completed with captured image
  void completeCurrentTask({
    required String imagePath,
    ValidationState? validationState,
    Map<String, dynamic>? metadata,
  }) {
    if (_currentIndex >= _tasks.length) return;
    
    _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
      status: TaskStatus.completed,
      capturedImagePath: imagePath,
      capturedAt: DateTime.now(),
      validationState: validationState,
      metadata: metadata,
    ));
    
    _moveToNextTask();
  }

  /// Skip current task
  void skipCurrentTask() {
    if (_currentIndex >= _tasks.length) return;
    
    _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
      status: TaskStatus.skipped,
    ));
    
    _moveToNextTask();
  }

  /// Mark current task as failed
  void failCurrentTask(String reason) {
    if (_currentIndex >= _tasks.length) return;
    
    _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
      status: TaskStatus.failed,
      metadata: {'failReason': reason},
    ));
    
    onTaskError?.call(reason);
    _moveToNextTask();
  }

  /// Retake a specific task
  void retakeTask(int index) {
    if (index < 0 || index >= _tasks.length) return;
    
    // Reset the task
    _updateTask(index, CaptureTaskItem(task: _tasks[index].task));
    
    // Move to that task
    _currentIndex = index;
    _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
      status: TaskStatus.inProgress,
    ));
    
    notifyListeners();
    onTaskChange?.call(_currentIndex, _tasks[_currentIndex]);
  }

  /// Move to a specific task index
  void goToTask(int index) {
    if (index < 0 || index >= _tasks.length) return;
    
    // Mark current as pending if not completed
    if (_currentIndex < _tasks.length && 
        _tasks[_currentIndex].status == TaskStatus.inProgress) {
      _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
        status: TaskStatus.pending,
      ));
    }
    
    _currentIndex = index;
    _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
      status: TaskStatus.inProgress,
    ));
    
    notifyListeners();
    onTaskChange?.call(_currentIndex, _tasks[_currentIndex]);
  }

  /// Get all completed capture paths
  List<String> getCompletedImagePaths() {
    return _tasks
        .where((t) => t.status == TaskStatus.completed && t.capturedImagePath != null)
        .map((t) => t.capturedImagePath!)
        .toList();
  }

  /// Get capture session summary
  CaptureSessionSummary getSummary() {
    return CaptureSessionSummary(
      totalTasks: totalTasks,
      completedTasks: completedTaskCount,
      skippedTasks: _tasks.where((t) => t.status == TaskStatus.skipped).length,
      failedTasks: _tasks.where((t) => t.status == TaskStatus.failed).length,
      capturedImages: getCompletedImagePaths(),
      sessionDuration: _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!) 
          : Duration.zero,
      averageQualityScore: _calculateAverageQualityScore(),
    );
  }

  void _moveToNextTask() {
    _currentIndex++;
    
    if (_currentIndex >= _tasks.length) {
      // All tasks done
      _isActive = false;
      _sessionTimer?.cancel();
      onAllTasksComplete?.call(_tasks);
    } else {
      // Start next task
      _updateTask(_currentIndex, _tasks[_currentIndex].copyWith(
        status: TaskStatus.inProgress,
      ));
      onTaskChange?.call(_currentIndex, _tasks[_currentIndex]);
    }
    
    notifyListeners();
  }

  void _updateTask(int index, CaptureTaskItem task) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index] = task;
    }
  }

  void _onSessionTimeout() {
    // Mark remaining tasks as skipped
    for (int i = _currentIndex; i < _tasks.length; i++) {
      if (_tasks[i].status == TaskStatus.pending || 
          _tasks[i].status == TaskStatus.inProgress) {
        _updateTask(i, _tasks[i].copyWith(
          status: TaskStatus.skipped,
          metadata: {'skipReason': 'session_timeout'},
        ));
      }
    }
    
    _isActive = false;
    onAllTasksComplete?.call(_tasks);
    notifyListeners();
  }

  double _calculateAverageQualityScore() {
    final completedWithValidation = _tasks
        .where((t) => t.status == TaskStatus.completed && 
                     t.validationState?.imageQuality != null)
        .toList();
    
    if (completedWithValidation.isEmpty) return 0;
    
    double total = 0;
    for (final task in completedWithValidation) {
      final quality = task.validationState!.imageQuality!;
      total += (quality.blurScore + quality.exposureScore) / 2;
    }
    
    return total / completedWithValidation.length;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}

/// Summary of a capture session
class CaptureSessionSummary {
  final int totalTasks;
  final int completedTasks;
  final int skippedTasks;
  final int failedTasks;
  final List<String> capturedImages;
  final Duration sessionDuration;
  final double averageQualityScore;

  const CaptureSessionSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.skippedTasks,
    required this.failedTasks,
    required this.capturedImages,
    required this.sessionDuration,
    required this.averageQualityScore,
  });

  bool get isComplete => completedTasks == totalTasks;
  bool get hasMinimumCaptures => completedTasks >= 2;
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0;
  
  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'skippedTasks': skippedTasks,
      'failedTasks': failedTasks,
      'capturedImages': capturedImages,
      'sessionDurationMs': sessionDuration.inMilliseconds,
      'averageQualityScore': averageQualityScore,
      'completionRate': completionRate,
    };
  }
}

/// Factory for creating task sets based on crop type
class CaptureTaskFactory {
  /// Create standard multi-angle task set
  static List<CaptureTask> createStandardTasks() {
    return CaptureTask.standardMultiAngleTasks;
  }

  /// Create task set for crop damage assessment
  static List<CaptureTask> createDamageAssessmentTasks() {
    return [
      const CaptureTask(
        id: 'damage_overview',
        type: CaptureTaskType.wideAngle,
        title: 'Damage Overview',
        description: 'Stand back and capture the entire damaged area',
      ),
      const CaptureTask(
        id: 'damage_closeup_1',
        type: CaptureTaskType.closeUp,
        title: 'Damage Close-up 1',
        description: 'Move close to show damage details clearly',
        requiredMinDistance: 0.1,
        requiredMaxDistance: 0.3,
      ),
      const CaptureTask(
        id: 'damage_closeup_2',
        type: CaptureTaskType.closeUp,
        title: 'Damage Close-up 2',
        description: 'Capture another damaged area',
        requiredMinDistance: 0.1,
        requiredMaxDistance: 0.3,
      ),
      const CaptureTask(
        id: 'healthy_comparison',
        type: CaptureTaskType.sideView,
        title: 'Healthy Comparison',
        description: 'Find a nearby healthy plant and capture it',
      ),
    ];
  }

  /// Create task set for crop growth monitoring
  static List<CaptureTask> createGrowthMonitoringTasks(CropGrowthStage stage) {
    final baseTasks = <CaptureTask>[
      const CaptureTask(
        id: 'plant_overview',
        type: CaptureTaskType.sideView,
        title: 'Plant Overview',
        description: 'Capture the full plant from the side',
      ),
    ];

    // Add stage-specific tasks
    switch (stage) {
      case CropGrowthStage.seedling:
        baseTasks.add(const CaptureTask(
          id: 'seedling_closeup',
          type: CaptureTaskType.closeUp,
          title: 'Seedling Close-up',
          description: 'Capture emerging leaves clearly',
          requiredMinDistance: 0.1,
          requiredMaxDistance: 0.3,
        ));
        break;
      case CropGrowthStage.vegetative:
        baseTasks.add(const CaptureTask(
          id: 'leaf_detail',
          type: CaptureTaskType.closeUp,
          title: 'Leaf Detail',
          description: 'Show leaf condition and color',
          requiredMinDistance: 0.1,
          requiredMaxDistance: 0.3,
        ));
        baseTasks.add(const CaptureTask(
          id: 'canopy_top',
          type: CaptureTaskType.topView,
          title: 'Canopy Top View',
          description: 'Look down at the plant from above',
          requiredMinPitch: -90,
          requiredMaxPitch: -60,
        ));
        break;
      case CropGrowthStage.flowering:
        baseTasks.add(const CaptureTask(
          id: 'flower_closeup',
          type: CaptureTaskType.closeUp,
          title: 'Flower Close-up',
          description: 'Capture flowers clearly',
          requiredMinDistance: 0.1,
          requiredMaxDistance: 0.3,
        ));
        break;
      case CropGrowthStage.fruiting:
        baseTasks.add(const CaptureTask(
          id: 'fruit_closeup',
          type: CaptureTaskType.closeUp,
          title: 'Fruit Close-up',
          description: 'Show fruit development stage',
          requiredMinDistance: 0.1,
          requiredMaxDistance: 0.3,
        ));
        break;
      case CropGrowthStage.maturity:
        baseTasks.add(const CaptureTask(
          id: 'mature_crop',
          type: CaptureTaskType.closeUp,
          title: 'Mature Crop',
          description: 'Show harvest-ready indicators',
          requiredMinDistance: 0.1,
          requiredMaxDistance: 0.3,
        ));
        baseTasks.add(const CaptureTask(
          id: 'field_yield',
          type: CaptureTaskType.wideAngle,
          title: 'Field Yield View',
          description: 'Capture wide view of field for yield assessment',
          requiredMinDistance: 2.0,
          requiredMaxDistance: 10.0,
        ));
        break;
      default:
        break;
    }

    return baseTasks;
  }

  /// Create minimal task set (for quick capture)
  static List<CaptureTask> createMinimalTasks() {
    return [
      const CaptureTask(
        id: 'quick_capture',
        type: CaptureTaskType.sideView,
        title: 'Quick Capture',
        description: 'Frame the crop in view and capture',
      ),
    ];
  }
}
