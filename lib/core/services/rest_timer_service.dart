import 'dart:async';

/// Service for managing rest timers between sets during workouts
/// 
/// Features:
/// - Countdown timer with stream updates
/// - Pause/resume functionality
/// - Add/subtract time during countdown
/// - Auto-completion notification
class RestTimerService {
  Timer? _timer;
  StreamController<int>? _controller;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isPaused = false;
  bool _isActive = false;

  /// Get the current remaining time in seconds
  int get remainingSeconds => _remainingSeconds;

  /// Get the total timer duration in seconds
  int get totalSeconds => _totalSeconds;

  /// Check if timer is currently active
  bool get isActive => _isActive;

  /// Check if timer is paused
  bool get isPaused => _isPaused;

  /// Get the progress percentage (0.0 to 1.0)
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  /// Start a new countdown timer
  /// 
  /// Returns a stream that emits the remaining seconds every second
  /// Completes when the timer reaches 0
  Stream<int> startTimer(int durationSeconds) {
    // Cancel any existing timer
    cancelTimer();

    _totalSeconds = durationSeconds;
    _remainingSeconds = durationSeconds;
    _isPaused = false;
    _isActive = true;

    _controller = StreamController<int>.broadcast();

    // Emit initial value
    _controller!.add(_remainingSeconds);

    // Start countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _remainingSeconds--;

        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _controller!.add(_remainingSeconds);
          _completeTimer();
        } else {
          _controller!.add(_remainingSeconds);
        }
      }
    });

    return _controller!.stream;
  }

  /// Pause the current timer
  void pauseTimer() {
    if (_isActive && !_isPaused) {
      _isPaused = true;
    }
  }

  /// Resume the paused timer
  void resumeTimer() {
    if (_isActive && _isPaused) {
      _isPaused = false;
    }
  }

  /// Cancel the timer and clean up resources
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;

    _remainingSeconds = 0;
    _totalSeconds = 0;
    _isPaused = false;
    _isActive = false;
  }

  /// Add time to the current timer
  /// 
  /// [seconds] can be negative to subtract time
  void addTime(int seconds) {
    if (!_isActive) return;

    _remainingSeconds += seconds;
    _totalSeconds += seconds;

    // Ensure we don't go negative
    if (_remainingSeconds < 0) {
      _remainingSeconds = 0;
    }

    // Emit updated time
    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(_remainingSeconds);
    }

    // Complete if we hit zero
    if (_remainingSeconds == 0) {
      _completeTimer();
    }
  }

  /// Skip directly to a specific time
  void skipToTime(int seconds) {
    if (!_isActive) return;

    _remainingSeconds = seconds.clamp(0, _totalSeconds);

    // Emit updated time
    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(_remainingSeconds);
    }

    // Complete if we hit zero
    if (_remainingSeconds == 0) {
      _completeTimer();
    }
  }

  /// Complete the timer and clean up
  void _completeTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _isPaused = false;

    // Close the stream
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
  }

  /// Format seconds into MM:SS string
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Get suggested rest time based on exercise type
  /// 
  /// Returns rest time in seconds
  static int getSuggestedRestTime({
    required bool isCompound,
    required int targetReps,
    required double? rpe,
  }) {
    // Compound exercises need more rest
    if (isCompound) {
      if (targetReps <= 5) return 180; // Heavy strength: 3 min
      if (targetReps <= 8) return 150; // Moderate: 2.5 min
      return 120; // Hypertrophy: 2 min
    } else {
      // Isolation exercises
      if (targetReps <= 8) return 90; // 1.5 min
      return 60; // 1 min
    }
  }

  /// Dispose of the service
  void dispose() {
    cancelTimer();
  }
}
