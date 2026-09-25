import 'package:audioplayers/audioplayers.dart';
import 'local_audio_focus.dart';

/// SFX-only service. Plays short sound effects (correct, wrong, flip, win).
/// Speech is handled by PhonicsAudioService (TTS) — no cross-dependency needed.
class AudioService {
  static AudioService _instance = AudioService._internal();
  factory AudioService() =>
      _instance._disposed ? _instance = AudioService._internal() : _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  bool _disposed = false;
  int _request = 0;

  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) stop();
  }

  Future<void> stop() async {
    _request++;
    if (_disposed) return;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _play(String asset) async {
    if (!_enabled || _disposed) return;
    final focus = LocalAudioFocus.claim();
    final request = _request + 1;
    await stop();
    if (_disposed || !_enabled || request != _request || !LocalAudioFocus.isCurrent(focus)) {
      return;
    }
    try {
      await _player.play(AssetSource('audio/$asset'));
    } catch (_) {}
  }

  Future<void> playTap()     => _play('tap.mp3');
  Future<void> playWin()     => _play('win.mp3');
  Future<void> playFlip()    => _play('flip.mp3');
  Future<void> playCorrect() => _play('correct.mp3');
  Future<void> playWrong()   => _play('wrong.mp3');

  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
    _player.dispose();
  }
}
