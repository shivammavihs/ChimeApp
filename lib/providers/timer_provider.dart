import 'dart:async';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

// ---------------------------------------------------------------------------
// Timer status enum
// ---------------------------------------------------------------------------
enum ChimeStatus { idle, running, paused, completed }

// ---------------------------------------------------------------------------
// Immutable state
// ---------------------------------------------------------------------------
class ChimeState {
  const ChimeState({
    required this.status,
    required this.remainingSeconds,
    required this.currentRep,
    required this.totalReps,
    required this.intervalSeconds,
  });

  final ChimeStatus status;

  /// Seconds left until the next chime
  final int remainingSeconds;

  /// Which repetition we're currently on (1-based, 0 = not started)
  final int currentRep;

  /// Total number of repetitions requested
  final int totalReps;

  /// Full interval duration in seconds
  final int intervalSeconds;

  bool get isIdle => status == ChimeStatus.idle;
  bool get isRunning => status == ChimeStatus.running;
  bool get isPaused => status == ChimeStatus.paused;
  bool get isCompleted => status == ChimeStatus.completed;

  /// Progress within the current interval [0.0, 1.0]
  double get intervalProgress {
    if (intervalSeconds == 0) return 0.0;
    return 1.0 - (remainingSeconds / intervalSeconds);
  }

  ChimeState copyWith({
    ChimeStatus? status,
    int? remainingSeconds,
    int? currentRep,
    int? totalReps,
    int? intervalSeconds,
  }) {
    return ChimeState(
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentRep: currentRep ?? this.currentRep,
      totalReps: totalReps ?? this.totalReps,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    );
  }
}

// ---------------------------------------------------------------------------
// Chime event — broadcast stream so widgets can react to each chime
// ---------------------------------------------------------------------------
final chimeEventProvider =
    StreamProvider<int>((ref) => ref.watch(timerProvider.notifier)._chimeStream);

// ---------------------------------------------------------------------------
// Timer provider
// ---------------------------------------------------------------------------
final timerProvider =
    StateNotifierProvider<ChimeTimerNotifier, ChimeState>((ref) {
  return ChimeTimerNotifier(ref);
});

class ChimeTimerNotifier extends StateNotifier<ChimeState> {
  ChimeTimerNotifier(this._ref)
      : super(const ChimeState(
          status: ChimeStatus.idle,
          remainingSeconds: 0,
          currentRep: 0,
          totalReps: 5,
          intervalSeconds: 180,
        )) {
    // Listen to background service ticks to keep state updated in real-time on mobile
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().on('timerTick').listen((event) {
        if (event != null && state.status != ChimeStatus.idle) {
          final remaining = event['remainingSeconds'] as int;
          final rep = event['currentRep'] as int;
          final statusStr = event['status'] as String;

          ChimeStatus status = ChimeStatus.running;
          if (statusStr == 'paused') {
            status = ChimeStatus.paused;
          } else if (statusStr == 'completed') {
            status = ChimeStatus.completed;
          }

          state = state.copyWith(
            remainingSeconds: remaining,
            currentRep: rep,
            status: status,
          );
        }
      });

      FlutterBackgroundService().on('timerCompleted').listen((event) {
        if (state.status != ChimeStatus.idle) {
          _ticker?.cancel();
          state = state.copyWith(
            status: ChimeStatus.completed,
            remainingSeconds: 0,
            currentRep: state.totalReps,
          );
        }
      });
    }
  }

  final Ref _ref;
  Timer? _ticker;
  final _chimeController = StreamController<int>.broadcast();
  Stream<int> get _chimeStream => _chimeController.stream;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  void start() async {
    if (state.isRunning) return;

    final intervalSecs = _ref.read(intervalSecondsTotal);
    final totalReps = _ref.read(totalRepsProvider);
    final customChimePath = _ref.read(customChimeSoundPathProvider);
    final selectedChimeType = _ref.read(selectedChimeTypeProvider) ?? 'default';

    state = ChimeState(
      status: ChimeStatus.running,
      remainingSeconds: intervalSecs,
      currentRep: 1,
      totalReps: totalReps,
      intervalSeconds: intervalSecs,
    );

    if (Platform.isAndroid || Platform.isIOS) {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
      service.invoke('startTimer', {
        'intervalSeconds': intervalSecs,
        'totalReps': totalReps,
        'customChimeSoundPath': customChimePath,
        'selectedChimeType': selectedChimeType,
      });
    } else {
      _startTicker();
    }
  }

  void pause() {
    if (!state.isRunning) return;
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('pauseTimer');
    } else {
      _ticker?.cancel();
      state = state.copyWith(status: ChimeStatus.paused);
    }
  }

  void resume() {
    if (!state.isPaused) return;
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('resumeTimer');
    } else {
      state = state.copyWith(status: ChimeStatus.running);
      _startTicker();
    }
  }

  void stop() {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('stopTimer');
    }
    _ticker?.cancel();
    state = const ChimeState(
      status: ChimeStatus.idle,
      remainingSeconds: 0,
      currentRep: 0,
      totalReps: 5,
      intervalSeconds: 180,
    );
  }


  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer _) {
    if (!state.isRunning) return;

    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining > 0) {
      state = state.copyWith(remainingSeconds: newRemaining);
      return;
    }

    // Chime fires
    _chimeController.add(state.currentRep);

    final nextRep = state.currentRep + 1;
    if (nextRep > state.totalReps) {
      // All done
      _ticker?.cancel();
      state = state.copyWith(
        status: ChimeStatus.completed,
        remainingSeconds: 0,
        currentRep: state.totalReps,
      );
    } else {
      // Next repetition
      state = state.copyWith(
        currentRep: nextRep,
        remainingSeconds: state.intervalSeconds,
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _chimeController.close();
    super.dispose();
  }
}
