import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rest_timer_service.dart';
import '../services/tempo_service.dart';

// ============================================================================
// REST TIMER PROVIDERS (New)
// ============================================================================

/// State for rest timer
class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isActive;
  final bool isPaused;
  final double progress;

  RestTimerState({
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isActive = false,
    this.isPaused = false,
    this.progress = 0.0,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isActive,
    bool? isPaused,
    double? progress,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      progress: progress ?? this.progress,
    );
  }

  String get formattedTime => RestTimerService.formatTime(remainingSeconds);
}

/// StateNotifier for rest timer
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  final RestTimerService _service;

  RestTimerNotifier(this._service) : super(RestTimerState());

  /// Start a new rest timer
  void startTimer(int durationSeconds) {
    _service.startTimer(durationSeconds).listen(
      (remaining) {
        state = state.copyWith(
          remainingSeconds: remaining,
          totalSeconds: _service.totalSeconds,
          isActive: _service.isActive,
          isPaused: _service.isPaused,
          progress: _service.progress,
        );
      },
      onDone: () {
        state = state.copyWith(
          isActive: false,
          isPaused: false,
        );
      },
    );

    state = state.copyWith(
      remainingSeconds: durationSeconds,
      totalSeconds: durationSeconds,
      isActive: true,
      isPaused: false,
      progress: 0.0,
    );
  }

  void pause() {
    _service.pauseTimer();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    _service.resumeTimer();
    state = state.copyWith(isPaused: false);
  }

  void cancel() {
    _service.cancelTimer();
    state = RestTimerState();
  }

  void addTime(int seconds) {
    _service.addTime(seconds);
  }

  void skipToTime(int seconds) {
    _service.skipToTime(seconds);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Provider for rest timer service
final restTimerServiceProvider = Provider<RestTimerService>((ref) {
  final service = RestTimerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for rest timer state
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  final service = ref.watch(restTimerServiceProvider);
  return RestTimerNotifier(service);
});

// ============================================================================
// TEMPO TIMER PROVIDERS (New)
// ============================================================================

/// State for tempo timer
class TempoTimerState {
  final bool isActive;
  final bool isPaused;
  final int currentRep;
  final TempoBeat? currentBeat;
  final String tempo;
  final int totalReps;

  TempoTimerState({
    this.isActive = false,
    this.isPaused = false,
    this.currentRep = 0,
    this.currentBeat,
    this.tempo = '3-0-1-0',
    this.totalReps = 0,
  });

  TempoTimerState copyWith({
    bool? isActive,
    bool? isPaused,
    int? currentRep,
    TempoBeat? currentBeat,
    String? tempo,
    int? totalReps,
  }) {
    return TempoTimerState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      currentRep: currentRep ?? this.currentRep,
      currentBeat: currentBeat ?? this.currentBeat,
      tempo: tempo ?? this.tempo,
      totalReps: totalReps ?? this.totalReps,
    );
  }

  int get totalTimeUnderTension {
    return TempoService.calculateSetTimeUnderTension(tempo, totalReps);
  }
}

/// StateNotifier for tempo timer
class TempoTimerNotifier extends StateNotifier<TempoTimerState> {
  final TempoService _service;

  TempoTimerNotifier(this._service) : super(TempoTimerState());

  void startTempo({required String tempo, required int reps}) {
    _service.startTempo(tempo: tempo, reps: reps).listen(
      (beat) {
        state = state.copyWith(
          currentBeat: beat,
          currentRep: beat.currentRep,
          isActive: _service.isActive,
          isPaused: _service.isPaused,
        );
      },
      onDone: () {
        state = state.copyWith(isActive: false, isPaused: false);
      },
    );

    state = state.copyWith(
      tempo: tempo,
      totalReps: reps,
      currentRep: 1,
      isActive: true,
      isPaused: false,
    );
  }

  void pause() {
    _service.pause();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    _service.resume();
    state = state.copyWith(isPaused: false);
  }

  void stop() {
    _service.stopTempo();
    state = TempoTimerState();
  }

  void skipToNextRep() {
    _service.skipToNextRep();
  }

  void skipToRep(int rep) {
    _service.skipToRep(rep);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Provider for tempo service
final tempoServiceProvider = Provider<TempoService>((ref) {
  final service = TempoService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for tempo timer state
final tempoTimerProvider = StateNotifierProvider<TempoTimerNotifier, TempoTimerState>((ref) {
  final service = ref.watch(tempoServiceProvider);
  return TempoTimerNotifier(service);
});

// ============================================================================
// ORIGINAL Timer State Notifier (For backward compatibility)
// ============================================================================

/// State for workout timer
class TimerState {
  final int seconds;
  final bool isRunning;
  final TimerType type;
  final int targetSeconds;

  const TimerState({
    this.seconds = 0,
    this.isRunning = false,
    this.type = TimerType.rest,
    this.targetSeconds = 0,
  });

  TimerState copyWith({
    int? seconds,
    bool? isRunning,
    TimerType? type,
    int? targetSeconds,
  }) {
    return TimerState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      type: type ?? this.type,
      targetSeconds: targetSeconds ?? this.targetSeconds,
    );
  }

  /// Get formatted time string (MM:SS)
  String get formattedTime {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Get progress percentage
  double get progress {
    if (targetSeconds == 0) return 0.0;
    return (seconds / targetSeconds).clamp(0.0, 1.0);
  }

  /// Check if timer completed
  bool get isCompleted => seconds >= targetSeconds && targetSeconds > 0;
}

/// Timer types
enum TimerType {
  rest,
  workout,
  countdown,
}

/// Notifier for managing timer state
class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(const TimerState());

  /// Start rest timer (counts down)
  void startRestTimer(int seconds) {
    stop(); // Stop any existing timer
    state = TimerState(
      seconds: seconds,
      targetSeconds: seconds,
      isRunning: true,
      type: TimerType.rest,
    );
    _startCountdown();
  }

  /// Start workout timer (counts up)
  void startWorkoutTimer() {
    stop(); // Stop any existing timer
    state = const TimerState(
      seconds: 0,
      isRunning: true,
      type: TimerType.workout,
    );
    _startCountup();
  }

  /// Start countdown timer
  void startCountdown(int seconds) {
    stop(); // Stop any existing timer
    state = TimerState(
      seconds: seconds,
      targetSeconds: seconds,
      isRunning: true,
      type: TimerType.countdown,
    );
    _startCountdown();
  }

  /// Pause timer
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resume timer
  void resume() {
    if (!state.isRunning) {
      state = state.copyWith(isRunning: true);
      if (state.type == TimerType.workout) {
        _startCountup();
      } else {
        _startCountdown();
      }
    }
  }

  /// Stop and reset timer
  void stop() {
    _timer?.cancel();
    state = const TimerState();
  }

  /// Add time to rest timer
  void addTime(int seconds) {
    if (state.type == TimerType.rest || state.type == TimerType.countdown) {
      state = state.copyWith(
        seconds: state.seconds + seconds,
        targetSeconds: state.targetSeconds + seconds,
      );
    }
  }

  /// Internal: Start countdown
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.seconds > 0) {
        state = state.copyWith(seconds: state.seconds - 1);
      } else {
        stop(); // Auto-stop when reaching 0
      }
    });
  }

  /// Internal: Start countup
  void _startCountup() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for timer state management
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

/// Stream provider for timer updates (for real-time UI updates)
final timerStreamProvider = StreamProvider<TimerState>((ref) {
  final timerNotifier = ref.watch(timerProvider.notifier);
  
  return Stream.periodic(const Duration(milliseconds: 100), (_) {
    return ref.watch(timerProvider);
  });
});

// ============================================================================
// Rest Timer Specific Provider (Controller)
// ============================================================================

/// Controller for rest timer operations (use restTimerProvider for state)
final restTimerControllerProvider = Provider<RestTimerController>((ref) {
  return RestTimerController(ref);
});

/// Controller for rest timer operations
class RestTimerController {
  final Ref _ref;

  RestTimerController(this._ref);

  /// Start rest timer with default or custom duration
  void start({int seconds = 90}) {
    _ref.read(timerProvider.notifier).startRestTimer(seconds);
  }

  /// Pause rest timer
  void pause() {
    _ref.read(timerProvider.notifier).pause();
  }

  /// Resume rest timer
  void resume() {
    _ref.read(timerProvider.notifier).resume();
  }

  /// Stop rest timer
  void stop() {
    _ref.read(timerProvider.notifier).stop();
  }

  /// Add 15 seconds
  void add15Seconds() {
    _ref.read(timerProvider.notifier).addTime(15);
  }

  /// Add 30 seconds
  void add30Seconds() {
    _ref.read(timerProvider.notifier).addTime(30);
  }

  /// Get current state
  TimerState get state => _ref.read(timerProvider);
}
