// lib/screens/voice_recognition_screen.dart
//
// Word order randomised every session via GameRoundRandomizer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';

class VoiceRecognitionScreen extends StatefulWidget {
  final Difficulty difficulty;
  const VoiceRecognitionScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<VoiceRecognitionScreen> createState() =>
      _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen>
    with GameSessionUi<VoiceRecognitionScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _requestingPermission = false;
  bool _evaluatedThisListen = false;
  bool _isAvailable = false;
  bool _isListening = false;
  int _listenGeneration = 0;
  bool _isInitialized = false;

  String _recognized = '';
  bool? _isCorrect;

  late List<Map<String, String>> _activeWords;
  int _wordIndex = 0;

  Map<String, String> get _current => _activeWords[_wordIndex];

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = voiceWords[widget.difficulty] ??
        voiceWords[Difficulty.easy]!;
    final indices = GameRoundRandomizer()
        .nextSession('voice', widget.difficulty, all.length);
    _activeWords = indices.map((i) => all[i]).toList();
    _wordIndex = 0;
    _recognized = '';
    _isCorrect = null;
  }

  Future<void> _initSpeech() async {
    try {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) setState(() { _isAvailable = false; _isInitialized = true; });
        return;
      }
      for (int attempt = 0; attempt < 2; attempt++) {
        if (!mounted) return;
        _isAvailable = await _speech.initialize(
          onStatus: (s) {
            if (s == 'done' || s == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
        ).timeout(const Duration(seconds: 6), onTimeout: () => false);
        if (_isAvailable) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {
      _isAvailable = false;
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _listen() async {
    if (_requestingPermission || _isCorrect == true) return;
    if (!_isInitialized) {
      setState(() => _requestingPermission = true);
      await _initSpeech();
      if (!mounted) return;
      setState(() => _requestingPermission = false);
    }
    if (!_isAvailable) return;
    if (_isListening) {
      _listenGeneration++;
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _recognized = '';
      _evaluatedThisListen = false;
      _isCorrect = null;
      _isListening = true;
    });

    final generation = ++_listenGeneration;
    final p = context.read<AppProvider>();
    await p.phonicsAudio.stop();
    await p.voiceFeedback.stop();
    await p.audio.stop();
    if (!mounted || generation != _listenGeneration || !_isListening) return;
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted && generation == _listenGeneration && !resultOpen) {
            setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) _evaluate(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 2),
          localeId: 'en_US',
        ),
      );
    } catch (_) {
      if (mounted && generation == _listenGeneration) {
        setState(() { _isListening = false; _isAvailable = false; });
      }
    }
  }

  void _evaluate(String recognized) async {
    if (_evaluatedThisListen || recognized.trim().isEmpty) {
      if (mounted) setState(() => _isListening = false);
      return;
    }
    _evaluatedThisListen = true;
    final target = _current['word']!.toLowerCase().trim();
    final heard = recognized.toLowerCase().trim();

    bool isCorrect;
    final lev = _levenshtein(target, heard);
    switch (widget.difficulty) {
      case Difficulty.easy:
        isCorrect = heard.contains(target) || target.contains(heard) || lev <= 1;
        break;
      case Difficulty.medium:
        isCorrect = heard.contains(target) || lev <= 1;
        break;
      case Difficulty.hard:
        isCorrect = heard == target || lev <= 1;
        break;
    }

    setState(() { _isCorrect = isCorrect; _isListening = false; });
    final provider = context.read<AppProvider>();
    scoredAttempts++;
    if (isCorrect) correctAttempts++;
    if (isCorrect) {
      awardGameXp((10 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      provider.audio.playCorrect();
    } else {
      provider.audio.playWrong();
    }
  }

  void _nextWord() {
    if (_isCorrect == null || _isListening || resultOpen) return;
    _listenGeneration++;
    if (_wordIndex < _activeWords.length - 1) {
      setState(() {
        _wordIndex++;
        _recognized = '';
        _evaluatedThisListen = false;
        _isCorrect = null;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    awardGameXp(15);
    context.read<AppProvider>().audio.playWin();
    showGameResult(() => setState(_buildSession));
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final matrix =
        List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) { matrix[i][0] = i; }
    for (int j = 0; j <= b.length; j++) { matrix[0][j] = j; }
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return matrix[a.length][b.length];
  }

  @override
  void dispose() {
    _listenGeneration++;
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
      title: 'Speak & Recognize',
      instructions: 'Hear the word. Say the word clearly.',
      difficulty: widget.difficulty,
      current: _wordIndex + 1,
      total: _activeWords.length,
      hasProgress: scoredAttempts > 0 && !resultOpen,
      onLeave: () => _speech.stop(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
            child: GameImageCard(
                word: _current['word'],
                label: _current['word'])),
        Text(_current['word'] ?? 'Content unavailable.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        AudioButton(
            phrase: _current['word'] ?? '', enabled: !_isListening),
        const SizedBox(height: 16),
        if (!_isInitialized) ...[
          const Text(
              'KidsPhonics uses the microphone only for Speak & Recognize.'),
          const Text('Your voice is used to recognize the word you say.'),
          const SizedBox(height: 12),
        ],
        const Text('Say the word clearly.', textAlign: TextAlign.center),
        ElevatedButton.icon(
            onPressed:
                _requestingPermission || _isCorrect == true || resultOpen
                    ? null
                    : _listen,
            icon: Icon(
                _isListening ? Icons.stop_circle_outlined : Icons.mic),
            label: Text(_requestingPermission
                ? 'Getting Ready…'
                : _isListening
                    ? 'Listening…'
                    : 'Start Listening')),
        if (_isInitialized && !_isAvailable)
          const Text(
              'Microphone or speech recognition is unavailable. Ask a parent to check device settings.'),
        if (_recognized.isNotEmpty)
          Text('I heard: $_recognized',
              style: const TextStyle(fontSize: 22)),
        if (_isCorrect != null)
          Text(_isCorrect! ? 'Recognized' : 'Try Again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        if (_isCorrect != null) GameFeedback(correct: _isCorrect!),
        if (_isCorrect != null)
          ElevatedButton(
              onPressed: _isListening || resultOpen ? null : _nextWord,
              child: const Text('Next Word')),
      ]));
}
