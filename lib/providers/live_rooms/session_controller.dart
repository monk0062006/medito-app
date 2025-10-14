import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/repositories/live_rooms/rooms_repository.dart';
import 'package:medito/providers/live_rooms/rooms_providers.dart';

enum SessionStatus { waiting, active, completed }

class SessionState {
  final String roomId;
  final int durationMinutes;
  final int remainingSeconds;
  final SessionStatus status;
  final bool bellEnabled;
  final DateTime? startTime;

  SessionState({
    required this.roomId,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.status,
    required this.bellEnabled,
    this.startTime,
  });

  SessionState copyWith({
    String? roomId,
    int? durationMinutes,
    int? remainingSeconds,
    SessionStatus? status,
    bool? bellEnabled,
    DateTime? startTime,
  }) {
    return SessionState(
      roomId: roomId ?? this.roomId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      bellEnabled: bellEnabled ?? this.bellEnabled,
      startTime: startTime ?? this.startTime,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this.roomId, this.duration) : super(SessionState(
    roomId: roomId,
    durationMinutes: duration,
    remainingSeconds: duration * 60,
    status: SessionStatus.waiting,
    bellEnabled: true,
  ));

  final String roomId;
  final int duration;
  Timer? _timer;

  void initialize() {
    // Only initialize if not already active
    if (state.status == SessionStatus.waiting) {
      // Start the session immediately
      state = state.copyWith(
        status: SessionStatus.active,
        startTime: DateTime.now(),
      );
      // Start the session countdown
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          status: SessionStatus.active,
        );
      } else {
        state = state.copyWith(
          status: SessionStatus.completed,
        );
        timer.cancel();
      }
    });
  }

  void toggleBell() {
    state = state.copyWith(bellEnabled: !state.bellEnabled);
  }

  void startSession() {
    if (state.status == SessionStatus.waiting) {
      state = state.copyWith(
        status: SessionStatus.active,
        startTime: DateTime.now(),
      );
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionControllerProvider = StateNotifierProvider.family<SessionController, SessionState, String>((ref, roomId) {
  // Get duration from room data
  final roomAsync = ref.watch(roomProvider(roomId));
  return roomAsync.when(
    data: (room) => SessionController(roomId, (room?.durationSeconds ?? 600) ~/ 60),
    loading: () => SessionController(roomId, 10),
    error: (_, __) => SessionController(roomId, 10),
  );
});