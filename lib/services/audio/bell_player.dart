import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class BellPlayer {
  final AudioPlayer _playerStart = AudioPlayer();
  final AudioPlayer _playerEnd = AudioPlayer();
  bool _isInitialized = false;

  Future<void> preload() async {
    try { 
      await _initializeAudioSession();
      await _playerStart.setAsset('assets/sounds/bell_start.mp3'); 
    } catch (_) {}
    try { 
      await _playerEnd.setAsset('assets/sounds/bell_end.mp3'); 
    } catch (_) {}
  }

  Future<void> _initializeAudioSession() async {
    if (_isInitialized) return;
    
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
      _isInitialized = true;
    } catch (e) {
      // Continue without audio session if it fails
    }
  }

  Future<void> playStart() async { 
    try { 
      await _ensureAudioSessionActive();
      await _playerStart.seek(Duration.zero); 
      await _playerStart.play(); 
    } catch (_) {} 
  }
  
  Future<void> playEnd() async { 
    try { 
      await _ensureAudioSessionActive();
      await _playerEnd.seek(Duration.zero); 
      await _playerEnd.play(); 
    } catch (_) {} 
  }

  Future<void> _ensureAudioSessionActive() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      // Continue if audio session activation fails
    }
  }

  Future<void> dispose() async {
    await _playerStart.dispose();
    await _playerEnd.dispose();
  }
}






