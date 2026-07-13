import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Simple Audio Service for single audio file playback
/// Handles playing one audio file from assets
class AudioService extends ChangeNotifier {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  /// The single audio file path
  /// Replace 'assets/audio/audio.mp3' with your actual audio file path
  static const String audioFilePath = 'assets/audio/audio.mp3';

  /// Play the single audio file
  Future<void> playAudio() async {
    try {
      // Load audio from assets
      final audioData = await rootBundle.load(audioFilePath);
      
      // Start playback
      _isPlaying = true;
      _totalDuration = const Duration(seconds: 180); // 3 minutes default
      
      notifyListeners();
      
      debugPrint('🎵 Playing audio from: $audioFilePath');
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Stop audio playback
  void stopAudio() {
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
    debugPrint('⏹️ Audio stopped');
  }

  /// Pause audio playback
  void pauseAudio() {
    _isPlaying = false;
    notifyListeners();
    debugPrint('⏸️ Audio paused');
  }

  /// Resume audio playback
  void resumeAudio() {
    _isPlaying = true;
    notifyListeners();
    debugPrint('▶️ Audio resumed');
  }

  @override
  void dispose() {
    stopAudio();
    super.dispose();
  }
}
