// lib/services/voice_feedback_service.dart
//
// TTS-based contextual voice feedback.
// Same engine setup as PhonicsAudioService — stop-then-speak, no awaitCompletion.

import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceFeedbackService {
  static VoiceFeedbackService _i = VoiceFeedbackService._internal();
  factory VoiceFeedbackService() =>
      _i._disposed ? _i = VoiceFeedbackService._internal() : _i;
  VoiceFeedbackService._internal();

  final FlutterTts _tts = FlutterTts();
  final _rng = Random();
  bool _disposed = false;
  bool _initialised = false;

  // ── Phrase banks ──────────────────────────────────────────────────────────
  static const _praise = [
    'Great job!',
    'Amazing!',
    'Well done!',
    'Wonderful!',
    'You are doing great!',
    'Fantastic!',
    'Super!',
    'Keep it up!',
  ];

  static const _wrong = [
    'Try again!',
    'Nice try! Keep going!',
    'Almost! Try once more.',
    'Good try! Listen carefully.',
    "That's okay! Let's try again.",
  ];

  // ── TTS init ──────────────────────────────────────────────────────────────
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
      await _tts.setSpeechRate(0.52); // slightly faster for short feedback
      await _tts.setPitch(1.15);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _say(String phrase) async {
    if (_disposed || phrase.trim().isEmpty) return;
    await _init();
    if (_disposed) return;
    try {
      await _tts.stop();
      await _tts.speak(phrase.trim());
    } catch (_) {}
  }

  // ── Praise ────────────────────────────────────────────────────────────────
  Future<void> playPraise() => _say(_praise[_rng.nextInt(_praise.length)]);

  // ── Wrong answer ──────────────────────────────────────────────────────────
  Future<void> playWrong() => _say(_wrong[_rng.nextInt(_wrong.length)]);

  // ── Game-specific wrong ───────────────────────────────────────────────────
  Future<void> playWrongSoundMatch()  => _say('Listen to the word again. Which letter does it start with?');
  Future<void> playWrongQuiz()        => _say('Not quite! Listen to the sound and try again.');
  Future<void> playWrongWordBuilder() => _say("That's not the right letter. Try again!");
  Future<void> playWrongMemory()      => _say("Not a match! Try to remember where you saw it.");
  Future<void> playWrongAlphabet()    => _say('Oops! Try the next letter in order!');
  Future<void> playWrongRhyming()     => _say('Listen carefully! Which word sounds the same at the end?');

  // ── Win / completion ──────────────────────────────────────────────────────
  Future<void> playWinPerfect()     => _say('Perfect score! You are amazing!');
  Future<void> playWinGreat()       => _say('Great work! You did really well!');
  Future<void> playWinGood()        => _say('Good job! Keep practicing and you will get even better!');
  Future<void> playWinSoundMatch()  => _say('Excellent! You matched all the sounds!');
  Future<void> playWinMemory()      => _say('All pairs found! Amazing memory!');
  Future<void> playWinQuiz()        => _say('Quiz done! Great work!');
  Future<void> playWinWordBuilder() => _say('All words spelled! Fantastic!');
  Future<void> playWinAlphabet()    => _say('Amazing! You know the whole alphabet!');
  Future<void> playWinRhyming()     => _say('You found all the rhymes! Wonderful!');
  Future<void> playWinVoice()       => _say('Practice done! You did amazing!');

  Future<void> playWinByScore(int correct, int total, {String game = ''}) {
    final ratio = total == 0 ? 1.0 : correct / total;
    final gameMap = <String, Future<void> Function()>{
      'sound_match':  playWinSoundMatch,
      'memory':       playWinMemory,
      'quiz':         playWinQuiz,
      'word_builder': playWinWordBuilder,
      'alphabet':     playWinAlphabet,
      'rhyming':      playWinRhyming,
      'voice':        playWinVoice,
    };
    if (ratio == 1.0) return playWinPerfect();
    if (ratio >= 0.7) return gameMap[game]?.call() ?? playWinGreat();
    return playWinGood();
  }

  // ── Game intros ───────────────────────────────────────────────────────────
  Future<void> playIntroSoundMatch()  => _say('What letter does it start with? Tap the correct letter!');
  Future<void> playIntroMemory()      => _say('Match the letter to its picture! Flip the cards to find pairs!');
  Future<void> playIntroQuiz()        => _say('Listen to the word and tap the letter it starts with!');
  Future<void> playIntroWordBuilder() => _say('Spell the word! Tap the missing letters!');
  Future<void> playIntroAlphabet()    => _say('A, B, C, D, E, F! Can you put the alphabet in order?');
  Future<void> playIntroRhyming()     => _say('Cat, Bat, Hat! They rhyme! Find the word that rhymes!');
  Future<void> playIntroVoice()       => _say('Tap the microphone and say the word out loud!');

  // ── Milestones ────────────────────────────────────────────────────────────
  Future<void> playLevelUp()              => _say('Level up! You are getting smarter every day!');
  Future<void> playAchievementFirst()     => _say('You mastered your first letter! Amazing start!');
  Future<void> playAchievement5Letters()  => _say('You mastered five letters! Keep going!');
  Future<void> playAchievement13Letters() => _say('Halfway there! You know thirteen letters!');
  Future<void> playAchievement26Letters() => _say('Alphabet Master! You know the whole alphabet!');
  Future<void> playAchievementXP()        => _say('One hundred experience points! Great work!');
  Future<void> playAchievementStreak()    => _say('Three days in a row! You are on a streak!');

  Future<void> checkRewardMilestones({
    required int xp,
    required int streak,
    required int prevXp,
    required int prevStreak,
    required int level,
    required int prevLevel,
  }) async {
    if (level > prevLevel) { await playLevelUp(); return; }
    if (xp >= 100 && prevXp < 100) { await playAchievementXP(); return; }
    if (streak >= 3 && prevStreak < 3) { await playAchievementStreak(); return; }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
  }
}
