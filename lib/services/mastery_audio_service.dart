// lib/services/mastery_audio_service.dart
//
// TTS-backed mastery audio. Extra slow rate (0.42) for assessment clarity.
// Same stop-then-speak pattern — no awaitSpeakCompletion.

import 'package:flutter_tts/flutter_tts.dart';

abstract interface class MasteryAudio {
  Future<bool> play(String phrase);
  Future<void> stop();
  Future<void> dispose();
}

class LocalMasteryAudio implements MasteryAudio {
  final FlutterTts _tts = FlutterTts();
  bool _disposed = false;
  bool _initialised = false;

  Future<void> _init() async {
    if (_initialised || _disposed) return;
    _initialised = true;
    try {
      final raw = await _tts.getLanguages;
      final langs = (raw as List?)?.map((l) => l.toString()).toList() ?? [];
      if (langs.any((l) => l.startsWith('en-US'))) {
        await _tts.setLanguage('en-US');
      } else if (langs.any((l) => l.startsWith('en-PH'))) {
        await _tts.setLanguage('en-PH');
      } else {
        await _tts.setLanguage('en');
      }
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  @override
  Future<bool> play(String phrase) async {
    final text = phrase.trim();
    if (_disposed || text.isEmpty) return false;
    await _init();
    if (_disposed) return false;
    try {
      await _tts.stop();
      final result = await _tts.speak(text);
      return result == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try { await _tts.stop(); } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
  }
}
