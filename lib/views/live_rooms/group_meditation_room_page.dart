import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/live_rooms/group_session_provider.dart';
import 'package:medito/views/live_rooms/reflection_modal.dart';

class GroupMeditationRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  
  const GroupMeditationRoomPage({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<GroupMeditationRoomPage> createState() => _GroupMeditationRoomPageState();
}

class _GroupMeditationRoomPageState extends ConsumerState<GroupMeditationRoomPage> {
  @override
  void initState() {
    super.initState();
    // Initialize the group session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupSessionProvider(widget.roomId).notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(groupSessionProvider(widget.roomId));
    
    // Show reflection modal when session is completed
    if (sessionState.status == GroupSessionStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showReflectionModal(context);
      });
    }
    
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () async {
            // Leave room when closing
            await ref.read(groupSessionProvider(widget.roomId).notifier).leaveRoom();
            Navigator.pop(context);
          },
        ),
        title: Text(
          '${(sessionState.room?.durationSeconds ?? 600) ~/ 60} Minute Group Meditation',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        ),
        actions: [
          // Show participant count
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, color: Theme.of(context).colorScheme.onSurface, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${sessionState.participants.length}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Group Status
              _buildGroupStatus(sessionState),
              
              const SizedBox(height: 30),
              
              // Timer Display
              _buildTimerDisplay(sessionState),
              
              const SizedBox(height: 15),
              
              // Instruction Text (only show during instruction phase)
              if (sessionState.status == GroupSessionStatus.instructions)
                _buildInstructionText(sessionState),
              
              const SizedBox(height: 30),
              
              // Participant Count (anonymous)
              _buildParticipantCount(sessionState),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              _buildActionButtons(sessionState),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupStatus(GroupSessionState sessionState) {
    String statusText;
    Color statusColor;
    
    switch (sessionState.status) {
      case GroupSessionStatus.waiting:
        if (sessionState.participants.isEmpty) {
          statusText = 'Waiting for others to join...';
          statusColor = Colors.orange;
        } else {
          statusText = '${sessionState.participants.length} people meditating together';
          statusColor = Colors.green;
        }
        break;
      case GroupSessionStatus.instructions:
        statusText = 'Preparing for meditation...';
        statusColor = Colors.blue;
        break;
      case GroupSessionStatus.active:
        statusText = 'Meditating together with ${sessionState.participants.length} people';
        statusColor = Colors.green;
        break;
      case GroupSessionStatus.completed:
        statusText = 'Group meditation completed!';
        statusColor = Colors.blue;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimerDisplay(GroupSessionState sessionState) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sessionState.status == GroupSessionStatus.instructions
                  ? '${sessionState.instructionCountdown}'
                  : _formatTime(sessionState.remainingSeconds),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (sessionState.status == GroupSessionStatus.instructions)
              Text(
                'Preparing',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              )
            else if (sessionState.status == GroupSessionStatus.active)
              Text(
                'meditating',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionText(GroupSessionState sessionState) {
    String instructionText;
    
    if (sessionState.instructionCountdown > 45) {
      instructionText = "🌿 Find a quiet, comfortable space\n💺 Sit or lie down in a relaxed position\n📱 Put your phone on silent";
    } else if (sessionState.instructionCountdown > 30) {
      instructionText = "👁️ Close your eyes gently\n🧘 Let your body settle into stillness\n🫁 Notice your natural breathing";
    } else if (sessionState.instructionCountdown > 15) {
      instructionText = "🫁 Take 3 deep breaths\n😌 Release any tension in your body\n🧠 Let go of thoughts and worries";
    } else if (sessionState.instructionCountdown > 5) {
      instructionText = "🎯 Focus on your breathing\n⏰ Meditation begins in a moment\n💫 You're ready to begin";
    } else {
      instructionText = "✨ Begin your meditation journey\n🕉️ Find peace within yourself";
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        instructionText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildParticipantCount(GroupSessionState sessionState) {
    // Count includes Bodhi (always present) + current user (if joined)
    final participantCount = sessionState.participants.length + (sessionState.isJoined ? 1 : 0);
    
    // Debug logging
    print('DEBUG: participantCount = $participantCount, isJoined = ${sessionState.isJoined}');
    print('DEBUG: participants = ${sessionState.participants}');
    
    // Always show participants if there are any, or if user is joined
    if (participantCount == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 48),
            SizedBox(height: 12),
            Text(
              'Be the first to join this meditation',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Show participant avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show Bodhi first (always present)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => _showBodhiInfo(context),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange,
                    child: const Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Show current user if joined
              if (sessionState.isJoined)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: const Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Show "+X more" if there are more than 5 participants
              if (participantCount > 5)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Text(
                      '+${participantCount - 5}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '$participantCount ${participantCount == 1 ? 'person' : 'people'} meditating',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Join the collective meditation',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  void _showBodhiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange,
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bodhi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your meditation companion',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Bodhi is always here to meditate with you. His name means "awakening" or "enlightenment" in Sanskrit, representing the spiritual journey of meditation.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🧘‍♂️ Always present in group meditations\n✨ Represents the collective energy\n🕉️ Symbol of spiritual awakening',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(GroupSessionState sessionState) {
    return Column(
      children: [
        // Join/Leave Button
        if (!sessionState.isJoined)
          ElevatedButton.icon(
            onPressed: () async {
              print('Join Group Meditation button pressed');
              try {
                await ref.read(groupSessionProvider(widget.roomId).notifier).joinRoom();
                print('Join room call completed');
              } catch (e) {
                print('Error in join room: $e');
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Join Group Meditation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(groupSessionProvider(widget.roomId).notifier).leaveRoom();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Leave Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Start Session Button (only show when waiting and user is joined)
        if (sessionState.isJoined && sessionState.status == GroupSessionStatus.waiting)
          ElevatedButton.icon(
            onPressed: () {
              ref.read(groupSessionProvider(widget.roomId).notifier).startSession();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Group Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Bell Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 8),
            Switch(
              value: sessionState.bellEnabled,
              onChanged: (value) {
                ref.read(groupSessionProvider(widget.roomId).notifier).toggleBell();
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Bell',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }


  void _showReflectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReflectionModal(
        roomId: widget.roomId,
        userId: 'anonymous_user', // TODO: Get actual user ID
        onSubmitted: () {
          Navigator.pop(context); // Close the modal
          Navigator.pop(context); // Go back to rooms list
        },
      ),
    );
  }
}
