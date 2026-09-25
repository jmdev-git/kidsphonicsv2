// lib/services/phonics_audio_service.dart
//
// TTS-based speech service.
// Primary: en-US  |  Fallback: en-PH  |  Generic fallback: en
// Rate 0.45 (slow/clear for kids), Pitch 1.1 (warm), Volume 1.0

import 'package:flutter_tts/flutter_tts.dart';

class PhonicsAudioService {
  static PhonicsAudioService _instance = PhonicsAudioService._internal();
  factory PhonicsAudioService() =>
      _instance._disposed
          ? _instance = PhonicsAudioService._internal()
          : _instance;
  PhonicsAudioService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _disposed = false;
  bool _initialised = false;

  // ── One-time setup ───────────────────────────────────────────────────────
  Future<void> _init() async {
    if (_initialised || _disposed) return;
    _initialised = true;
    try {
      // Language selection — en-US → en-PH → en
      final raw = await _tts.getLanguages;
      final langs = (raw as List?)?.map((l) => l.toString()).toList() ?? [];
      if (langs.any((l) => l.startsWith('en-US'))) {
        await _tts.setLanguage('en-US');
      } else if (langs.any((l) => l.startsWith('en-PH'))) {
        await _tts.setLanguage('en-PH');
      } else {
        await _tts.setLanguage('en');
      }
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);
      // Do NOT call awaitSpeakCompletion — it blocks on some Android versions
    } catch (_) {}
  }

  // ── Stop ─────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Speak [phrase]. Returns true immediately after handing off to TTS engine.
  /// Does NOT await completion — avoids the Android blocking bug.
  Future<bool> playInstruction(String phrase) async {
    final text = phrase.trim();
    if (_disposed || text.isEmpty) return false;
    await _init();
    if (_disposed) return false;
    try {
      await _tts.stop();               // stop previous utterance first
      final result = await _tts.speak(text);
      return result == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> tryPlay(String phrase) async {
    await playInstruction(phrase);
  }

  Future<void> tryPlayHint(String phrase) async {
    await playInstruction(phrase);
  }

  /// TTS is always available for any non-empty phrase.
  static String? assetForPhrase(String phrase) =>
      phrase.trim().isNotEmpty ? '__tts__' : null;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
  }
}
