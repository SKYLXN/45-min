import 'dart:async';

/// Tempo phase of a rep (e.g., for "3-0-1-0")
enum TempoPhase {
  eccentric,  // Lowering phase
  bottomPause, // Pause at bottom
  concentric, // Lifting phase
  topPause,   // Pause at top
}

/// Tempo beat event with phase and timing
class TempoBeat {
  final TempoPhase phase;
  final int secondsInPhase;
  final int totalSecondsInPhase;
  final int currentRep;
  final double progress; // 0.0 to 1.0 for current phase

  TempoBeat({
    required this.phase,
    required this.secondsInPhase,
    required this.totalSecondsInPhase,
    required this.currentRep,
    required this.progress,
  });

  /// Get user-friendly phase name
  String get phaseName {
    switch (phase) {
      case TempoPhase.eccentric:
        return 'Lower';
      case TempoPhase.bottomPause:
        return 'Hold Bottom';
      case TempoPhase.concentric:
        return 'Lift';
      case TempoPhase.topPause:
        return 'Hold Top';
    }
  }

  /// Get emoji for phase
  String get phaseEmoji {
    switch (phase) {
      case TempoPhase.eccentric:
        return '⬇️';
      case TempoPhase.bottomPause:
        return '⏸️';
      case TempoPhase.concentric:
        return '⬆️';
      case TempoPhase.topPause:
        return '⏸️';
    }
  }
}

/// Service for managing tempo guidance during exercise execution
/// 
/// Tempo format: "ECCENTRIC-PAUSE_BOTTOM-CONCENTRIC-PAUSE_TOP"
/// Example: "3-0-1-0" means:
/// - 3 seconds lowering
/// - 0 seconds pause at bottom
/// - 1 second lifting
/// - 0 seconds pause at top
class TempoService {
  Timer? _timer;
  StreamController<TempoBeat>? _controller;
  bool _isActive = false;
  bool _isPaused = false;
  
  int _currentRep = 1;
  int _totalReps = 0;
  TempoPhase _currentPhase = TempoPhase.eccentric;
  int _secondsInCurrentPhase = 0;
  
  // Tempo values (in seconds)
  int _eccentricSeconds = 0;
  int _bottomPauseSeconds = 0;
  int _concentricSeconds = 0;
  int _topPauseSeconds = 0;

  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  int get currentRep => _currentRep;
  TempoPhase get currentPhase => _currentPhase;

  /// Parse tempo string into individual phase durations
  /// 
  /// Format: "3-0-1-0" or "3010"
  /// Returns: (eccentric, bottomPause, concentric, topPause)
  static (int, int, int, int) parseTempo(String tempo) {
    // Remove any spaces
    tempo = tempo.replaceAll(' ', '');

    // Try parsing with dashes
    if (tempo.contains('-')) {
      final parts = tempo.split('-');
      if (parts.length == 4) {
        return (
          int.tryParse(parts[0]) ?? 3,
          int.tryParse(parts[1]) ?? 0,
          int.tryParse(parts[2]) ?? 1,
          int.tryParse(parts[3]) ?? 0,
        );
      }
    }

    // Try parsing as continuous digits (e.g., "3010")
    if (tempo.length == 4 && tempo.runes.every((r) => r >= 48 && r <= 57)) {
      return (
        int.parse(tempo[0]),
        int.parse(tempo[1]),
        int.parse(tempo[2]),
        int.parse(tempo[3]),
      );
    }

    // Default tempo (controlled eccentric, explosive concentric)
    return (3, 0, 1, 0);
  }

  /// Calculate total time under tension for one rep (in seconds)
  static int calculateTimeUnderTension(String tempo) {
    final (ecc, bPause, con, tPause) = parseTempo(tempo);
    return ecc + bPause + con + tPause;
  }

  /// Calculate total time under tension for a set
  static int calculateSetTimeUnderTension(String tempo, int reps) {
    return calculateTimeUnderTension(tempo) * reps;
  }

  /// Start tempo guidance for a set
  /// 
  /// Returns a stream that emits [TempoBeat] events every second
  Stream<TempoBeat> startTempo({
    required String tempo,
    required int reps,
  }) {
    // Cancel any existing timer
    stopTempo();

    // Parse tempo
    final (ecc, bPause, con, tPause) = parseTempo(tempo);
    _eccentricSeconds = ecc;
    _bottomPauseSeconds = bPause;
    _concentricSeconds = con;
    _topPauseSeconds = tPause;

    _totalReps = reps;
    _currentRep = 1;
    _currentPhase = TempoPhase.eccentric;
    _secondsInCurrentPhase = 0;
    _isActive = true;
    _isPaused = false;

    _controller = StreamController<TempoBeat>.broadcast();

    // Emit initial beat
    _emitBeat();

    // Start tempo ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _tick();
      }
    });

    return _controller!.stream;
  }

  /// Advance to the next phase
  void _tick() {
    _secondsInCurrentPhase++;

    final currentPhaseDuration = _getCurrentPhaseDuration();

    if (_secondsInCurrentPhase >= currentPhaseDuration) {
      // Move to next phase
      _advancePhase();
    }

    _emitBeat();
  }

  /// Get duration of current phase
  int _getCurrentPhaseDuration() {
    switch (_currentPhase) {
      case TempoPhase.eccentric:
        return _eccentricSeconds;
      case TempoPhase.bottomPause:
        return _bottomPauseSeconds;
      case TempoPhase.concentric:
        return _concentricSeconds;
      case TempoPhase.topPause:
        return _topPauseSeconds;
    }
  }

  /// Advance to the next phase or rep
  void _advancePhase() {
    _secondsInCurrentPhase = 0;

    switch (_currentPhase) {
      case TempoPhase.eccentric:
        _currentPhase = TempoPhase.bottomPause;
        if (_bottomPauseSeconds == 0) _advancePhase(); // Skip if 0 seconds
        break;
      case TempoPhase.bottomPause:
        _currentPhase = TempoPhase.concentric;
        break;
      case TempoPhase.concentric:
        _currentPhase = TempoPhase.topPause;
        if (_topPauseSeconds == 0) _advancePhase(); // Skip if 0 seconds
        break;
      case TempoPhase.topPause:
        // Move to next rep
        _currentRep++;
        if (_currentRep > _totalReps) {
          // Set complete
          _completeSet();
        } else {
          _currentPhase = TempoPhase.eccentric;
        }
        break;
    }
  }

  /// Emit current beat
  void _emitBeat() {
    if (_controller != null && !_controller!.isClosed) {
      final phaseDuration = _getCurrentPhaseDuration();
      final progress = phaseDuration > 0 
          ? _secondsInCurrentPhase / phaseDuration 
          : 1.0;

      _controller!.add(TempoBeat(
        phase: _currentPhase,
        secondsInPhase: _secondsInCurrentPhase,
        totalSecondsInPhase: phaseDuration,
        currentRep: _currentRep,
        progress: progress.clamp(0.0, 1.0),
      ));
    }
  }

  /// Pause tempo guidance
  void pause() {
    if (_isActive && !_isPaused) {
      _isPaused = true;
    }
  }

  /// Resume tempo guidance
  void resume() {
    if (_isActive && _isPaused) {
      _isPaused = false;
    }
  }

  /// Skip to next rep
  void skipToNextRep() {
    if (!_isActive) return;

    _currentRep++;
    if (_currentRep > _totalReps) {
      _completeSet();
    } else {
      _currentPhase = TempoPhase.eccentric;
      _secondsInCurrentPhase = 0;
      _emitBeat();
    }
  }

  /// Skip to specific rep
  void skipToRep(int rep) {
    if (!_isActive || rep < 1 || rep > _totalReps) return;

    _currentRep = rep;
    _currentPhase = TempoPhase.eccentric;
    _secondsInCurrentPhase = 0;
    _emitBeat();
  }

  /// Complete the set
  void _completeSet() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _isPaused = false;

    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
  }

  /// Stop tempo guidance
  void stopTempo() {
    _timer?.cancel();
    _timer = null;

    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;

    _isActive = false;
    _isPaused = false;
    _currentRep = 1;
    _totalReps = 0;
  }

  /// Dispose of the service
  void dispose() {
    stopTempo();
  }
}
