// lib/screens/missing_vowel_screen.dart
//
// Missing Vowel — shows a word with the vowel blanked out (C_T, D_G, S_N).
// Child taps the correct vowel to complete the word.
//
// Easy   : 3 short CVC words, 3 vowel choices (A, E, I)
// Medium : 5 words, 4 vowel choices (A, E, I, O)
// Hard   : 7 words, all 5 vowels (A, E, I, O, U)
//
// Puzzle order randomised every session via GameRoundRandomizer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class MissingVowelScreen extends StatefulWidget {
  final Difficulty difficulty;
  const MissingVowelScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<MissingVowelScreen> createState() => _MissingVowelScreenState();
}

class _MissingVowelScreenState extends State<MissingVowelScreen>
    with GameSessionUi<MissingVowelScreen> {
  late List<VowelPuzzle> _activePuzzles;
  int _index = 0;
  String? _picked;
  bool _answered = false;

  VowelPuzzle get _puzzle => _activePuzzles[_index];
  List<String> get _vowels =>
      vowelChoicesFor(widget.difficulty, _puzzle.vowel);

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = vowelPuzzlesFor(widget.difficulty);
    final indices = GameRoundRandomizer()
        .nextSession('missing_vowel', widget.difficulty, all.length);
    _activePuzzles = indices.map((i) => all[i]).toList();
    _index = 0;
    _picked = null;
    _answered = false;
  }

  void _pick(String vowel) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = vowel == _puzzle.vowel;
    setState(() => _picked = vowel);

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() => _answered = true);
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 1300));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_index < _activePuzzles.length - 1) {
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
      });
    } else {
      _showResults();
    }
  }

  void _restart() => setState(_buildSession);

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((15 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    showGameResult(_restart, backLabel: 'Back to Games');
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'Missing Vowel',
        instructions: 'Hear the word. Choose the missing vowel.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _activePuzzles.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: GameImageCard(
                  word: _puzzle.word[0] +
                      _puzzle.word.substring(1).toLowerCase())),
          const SizedBox(height: KidsUi.padding),
          Text(_puzzle.display,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase:
                  _puzzle.word[0] + _puzzle.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          ..._vowels.map((option) => GameAnswerButton(
              label: option,
              selected: _picked == option,
              result: _picked == option ? option == _puzzle.vowel : null,
              onPressed: _answered || _picked != null || resultOpen
                  ? null
                  : () => _pick(option))),
          if (_picked != null)
            GameFeedback(correct: _picked == _puzzle.vowel),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
