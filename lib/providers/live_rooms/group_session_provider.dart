import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medito/repositories/live_rooms/rooms_repository.dart';
import 'package:medito/models/live_rooms/room_model.dart';
import 'package:medito/services/audio/bell_player.dart';

enum GroupSessionStatus { waiting, instructions, active, completed }

class GroupSessionState {
  final String roomId;
  final RoomModel? room;
  final GroupSessionStatus status;
  final int remainingSeconds;
  final List<Map<String, dynamic>> participants;
  final bool isJoined;
  final DateTime? sessionStartTime;
  final String? currentUserId;
  final bool bellEnabled;
  final int instructionCountdown;

  GroupSessionState({
    required this.roomId,
    this.room,
    required this.status,
    required this.remainingSeconds,
    required this.participants,
    required this.isJoined,
    this.sessionStartTime,
    this.currentUserId,
    required this.bellEnabled,
    required this.instructionCountdown,
  });

  GroupSessionState copyWith({
    String? roomId,
    RoomModel? room,
    GroupSessionStatus? status,
    int? remainingSeconds,
    List<Map<String, dynamic>>? participants,
    bool? isJoined,
    DateTime? sessionStartTime,
    String? currentUserId,
    bool? bellEnabled,
    int? instructionCountdown,
  }) {
    return GroupSessionState(
      roomId: roomId ?? this.roomId,
      room: room ?? this.room,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      participants: participants ?? this.participants,
      isJoined: isJoined ?? this.isJoined,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      currentUserId: currentUserId ?? this.currentUserId,
      bellEnabled: bellEnabled ?? this.bellEnabled,
      instructionCountdown: instructionCountdown ?? this.instructionCountdown,
    );
  }
}

class GroupSessionController extends StateNotifier<GroupSessionState> with WidgetsBindingObserver {
  GroupSessionController(this.roomId) : super(GroupSessionState(
    roomId: roomId,
    status: GroupSessionStatus.waiting,
    remainingSeconds: 0,
    participants: [],
    isJoined: false,
    currentUserId: Supabase.instance.client.auth.currentUser?.id,
    bellEnabled: true,
    instructionCountdown: 60, // 60 seconds of instructions
  )) {
    WidgetsBinding.instance.addObserver(this);
  }

  final String roomId;
  final RoomsRepository _roomsRepository = RoomsRepository();
  final BellPlayer _bellPlayer = BellPlayer();
  Timer? _timer;
  Timer? _pollingTimer;
  RealtimeChannel? _roomChannel;
  RealtimeChannel? _presenceChannel;
  
  // Background persistence
  DateTime? _instructionStartTime;
  DateTime? _meditationStartTime;
  int _totalInstructionSeconds = 60;
  int _totalMeditationSeconds = 0;

  // Helper method to ensure Bodhi is always in the participants list
  List<Map<String, dynamic>> _ensureBodhiPresent(List<Map<String, dynamic>> participants) {
    print('DEBUG: _ensureBodhiPresent called with ${participants.length} participants');
    if (!participants.any((p) => p['id'] == 'demo_user_zen')) {
      print('DEBUG: Adding Bodhi to participants list');
      participants.add({
        'id': 'demo_user_zen',
        'name': 'Bodhi',
        'joined_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      });
    } else {
      print('DEBUG: Bodhi already present in participants list');
    }
    print('DEBUG: Final participants count: ${participants.length}');
    return participants;
  }

  void initialize() async {
    try {
      // Initialize bell player
      await _bellPlayer.preload();
      
      // Get room data
      final rooms = await _roomsRepository.getRooms();
      final room = rooms.firstWhere((r) => r.id == roomId);

      // Add demo user to initial participants
      final initialParticipants = [
        {
          'id': 'demo_user_zen',
          'name': 'Bodhi',
          'joined_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        }
      ];
      
      print('DEBUG: Setting initial participants: ${initialParticipants.length}');
      state = state.copyWith(
        room: room,
        remainingSeconds: room.durationSeconds,
        participants: initialParticipants,
      );
      print('DEBUG: State updated with participants: ${state.participants.length}');

      // Try to subscribe to realtime, fallback to polling if it fails
      try {
        _subscribeToRoom();
        _subscribeToPresence();
      } catch (e) {
        print('Realtime not available, using polling fallback: $e');
        _startPolling();
      }
      
    } catch (e) {
      print('Error initializing group session: $e');
    }
  }

  void _subscribeToRoom() {
    _roomChannel = _roomsRepository.subscribeToRoom(roomId, (roomData) {
      if (roomData != null) {
        final room = RoomModel.fromJson(roomData);
        
        // Preserve existing participants (including Bodhi) when updating room
        final currentParticipants = state.participants;
        state = state.copyWith(room: room, participants: currentParticipants);
        
        // Check if session should start
        _checkSessionStatus();
      }
    });
  }

  void _subscribeToPresence() {
    _presenceChannel = _roomsRepository.subscribeToPresence(roomId, (presenceState) {
      // For demo purposes, ignore real presence data and only show Bodhi
      final participants = <Map<String, dynamic>>[];
      
      // Always ensure Bodhi is present
      final participantsWithBodhi = _ensureBodhiPresent(participants);
      
      print('DEBUG: Presence update - setting participants: ${participantsWithBodhi.length}');
      state = state.copyWith(participants: participantsWithBodhi);
    });
  }

  void _startPolling() {
    // Fallback polling when Realtime is not available
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final rooms = await _roomsRepository.getRooms();
        final room = rooms.firstWhere((r) => r.id == roomId);
        
        // For demo purposes, ignore real database participants and only show Bodhi
        // Convert room participants to presence format for display (but filter out real users for demo)
        final participants = <Map<String, dynamic>>[];
        
        // Always ensure Bodhi is present
        final participantsWithBodhi = _ensureBodhiPresent(participants);
        
        state = state.copyWith(
          room: room,
          participants: participantsWithBodhi,
        );
        _checkSessionStatus();
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _checkSessionStatus() {
    if (state.room != null) {
      final now = DateTime.now();
      final room = state.room!;
      
      // Simple logic: if room is active and has participants, start session
      if (room.enabled && room.participants.isNotEmpty) {
        if (state.status == GroupSessionStatus.waiting) {
          _startGroupSession();
        }
      }
    }
  }

  void _startGroupSession() {
    final now = DateTime.now();
    _instructionStartTime = now;
    _totalMeditationSeconds = state.room?.durationSeconds ?? 300; // Default 5 minutes
    
    state = state.copyWith(
      status: GroupSessionStatus.instructions,
      sessionStartTime: now,
      instructionCountdown: _totalInstructionSeconds,
      remainingSeconds: _totalMeditationSeconds,
    );
    
    _startInstructionCountdown();
  }

  void _startInstructionCountdown() {
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateInstructionCountdown();
    });
  }
  
  void _updateInstructionCountdown() {
    if (_instructionStartTime == null) return;
    
    final now = DateTime.now();
    final elapsed = now.difference(_instructionStartTime!).inSeconds;
    final remaining = _totalInstructionSeconds - elapsed;
    
    if (remaining > 0) {
      state = state.copyWith(instructionCountdown: remaining);
    } else {
      // Instructions finished, start the actual meditation
      _meditationStartTime = now;
      state = state.copyWith(
        status: GroupSessionStatus.active,
        instructionCountdown: 0,
      );
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    
    // Play start bell if enabled
    if (state.bellEnabled) {
      _bellPlayer.playStart();
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateMeditationCountdown();
    });
  }
  
  void _updateMeditationCountdown() {
    if (_meditationStartTime == null) return;
    
    final now = DateTime.now();
    final elapsed = now.difference(_meditationStartTime!).inSeconds;
    final remaining = _totalMeditationSeconds - elapsed;
    
    if (remaining > 0) {
      state = state.copyWith(remainingSeconds: remaining);
    } else {
      // Play end bell if enabled
      if (state.bellEnabled) {
        _bellPlayer.playEnd();
      }
      
      state = state.copyWith(
        status: GroupSessionStatus.completed,
        remainingSeconds: 0,
      );
      _timer?.cancel();
    }
  }

  Future<void> joinRoom() async {
    // Generate a user ID if none exists
    String userId = state.currentUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    if (!state.isJoined) {
      try {
        print('Joining room with user ID: $userId');
        
        await _roomsRepository.joinRoom(roomId, userId);
        
        // Track presence
        await _presenceChannel?.track({
          'name': 'User ${userId.substring(0, 8)}',
          'joined_at': DateTime.now().toIso8601String(),
        });
        
        // For demo purposes, don't add current user to display - only show Bodhi
        final updatedParticipants = <Map<String, dynamic>>[];
        print('DEBUG: Current participants before adding user: ${updatedParticipants.length}');
        
        // Ensure Bodhi is always present (but don't add current user to display)
        final participantsWithBodhi = _ensureBodhiPresent(updatedParticipants);
        print('DEBUG: Final participants after join: ${participantsWithBodhi.length}');
        
        state = state.copyWith(
          isJoined: true,
          currentUserId: userId,
          participants: participantsWithBodhi,
        );
        
        // Check if we should start the session
        _checkSessionStatus();
        
        print('Successfully joined room');
        
      } catch (e) {
        print('Error joining room: $e');
        // Still mark as joined for local state even if server call fails
        state = state.copyWith(
          isJoined: true,
          currentUserId: userId,
        );
      }
    }
  }

  Future<void> leaveRoom() async {
    if (state.isJoined) {
      try {
        if (state.currentUserId != null) {
          await _roomsRepository.leaveRoom(roomId, state.currentUserId!);
        }
        
        // Untrack presence
        await _presenceChannel?.untrack();
        
        // Update local participants list immediately (remove current user but keep Bodhi)
        final updatedParticipants = state.participants.where((p) => p['id'] != state.currentUserId).toList();
        
        // Ensure Bodhi is always present
        final participantsWithBodhi = _ensureBodhiPresent(updatedParticipants);
        
        state = state.copyWith(
          isJoined: false,
          participants: participantsWithBodhi,
        );
        
        print('Successfully left room');
        
      } catch (e) {
        print('Error leaving room: $e');
        // Still mark as left for local state
        state = state.copyWith(isJoined: false);
      }
    }
  }

  void startSession() {
    if (state.status == GroupSessionStatus.waiting) {
      _startGroupSession();
    }
  }

  void toggleBell() {
    state = state.copyWith(bellEnabled: !state.bellEnabled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - recalculate timers based on elapsed time
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background - keep timers running but they'll be recalculated on resume
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }
  
  void _onAppResumed() {
    // Recalculate current state based on elapsed time since start
    if (state.status == GroupSessionStatus.instructions && _instructionStartTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_instructionStartTime!).inSeconds;
      
      if (elapsed >= _totalInstructionSeconds) {
        // Instructions should have finished - transition to meditation
        _meditationStartTime = _instructionStartTime!.add(Duration(seconds: _totalInstructionSeconds));
        state = state.copyWith(
          status: GroupSessionStatus.active,
          instructionCountdown: 0,
        );
        _startCountdown();
      } else {
        _updateInstructionCountdown();
      }
    } else if (state.status == GroupSessionStatus.active && _meditationStartTime != null) {
      _updateMeditationCountdown();
    }
    
    // Check if meditation should have completed while app was in background
    if (state.status == GroupSessionStatus.active && _meditationStartTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_meditationStartTime!).inSeconds;
      if (elapsed >= _totalMeditationSeconds) {
        // Meditation should have completed - trigger completion
        if (state.bellEnabled) {
          _bellPlayer.playEnd();
        }
        state = state.copyWith(
          status: GroupSessionStatus.completed,
          remainingSeconds: 0,
        );
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _roomChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _bellPlayer.dispose();
    super.dispose();
  }
}

final groupSessionProvider = StateNotifierProvider.family<GroupSessionController, GroupSessionState, String>((ref, roomId) {
  return GroupSessionController(roomId);
});
