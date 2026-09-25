import '../widgets/mascot_guide.dart';
// lib/screens/rhyming_words_screen.dart
//
// Rhyming Words lesson with Easy / Medium / Hard difficulty.
//
// Easy  : 3 choices, very simple CVC rhymes (cat/bat, dog/log…)
// Medium: 4 choices, slightly longer words
// Hard  : 5 choices, trickier rhymes with more distractors
//
// Round order is randomised every session via GameRoundRandomizer —
// never starts on the same round twice in a row.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class RhymingWordsScreen extends StatefulWidget {
  final Difficulty difficulty;
  const RhymingWordsScreen({super.key, this.difficulty = Difficulty.medium});

  @override
  State<RhymingWordsScreen> createState() => _RhymingWordsScreenState();
}

class _RhymingWordsScreenState extends State<RhymingWordsScreen>
    with GameSessionUi<RhymingWordsScreen> {
  late List<RhymeRound> _activeRounds;
  int _roundIndex = 0;
  String? _picked;
  bool _answered = false;
  late List<RhymeOption> _shuffledOptions;

  List<RhymeRound> get _allRounds =>
      rhymeRoundsForDifficulty(widget.difficulty);
  RhymeRound get _round => _activeRounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  // Build a fresh randomised session — different start each play.
  void _buildSession() {
    final all = _allRounds;
    final indices = GameRoundRandomizer()
        .nextSession('rhyming', widget.difficulty, all.length);
    _activeRounds = indices.map((i) => all[i]).toList();
    _roundIndex = 0;
    _picked = null;
    _answered = false;
    _shuffleOptions();
  }

  void _shuffleOptions() {
    _shuffledOptions = List<RhymeOption>.from(_round.options)..shuffle();
  }

  void _pick(String word) async {
    if (_answered) return;
    final isCorrect = word == _round.correctRhyme;
    setState(() {
      _picked = word;
      _answered = true;
    });
    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    } else {
      provider.audio.playWrong();
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_roundIndex < _activeRounds.length - 1) {
      setState(() {
        _roundIndex++;
        _picked = null;
        _answered = false;
        _shuffleOptions();
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
    awardGameXp((20 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    provider.markRhymingWordsDone();
    showGameResult(_restart, backLabel: 'Back to Lessons');
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        mascot: LearningMascot.wigloo,
        title: 'Rhyming Words',
        instructions: 'Hear the word. Tap the word that rhymes.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _activeRounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: GameImageCard(
                  word: _round.word[0] +
                      _round.word.substring(1).toLowerCase())),
          const SizedBox(height: KidsUi.padding),
          Text('What rhymes with ${_round.word}?',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase:
                  _round.word[0] + _round.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          ..._shuffledOptions.map((option) => GameAnswerButton(
              label: option.word,
              visual: GameImageCard(
                  word: option.word[0] +
                      option.word.substring(1).toLowerCase(),
                  label: option.word),
              selected: _picked == option.word,
              result: _picked == option.word
                  ? option.word == _round.correctRhyme
                  : null,
              onPressed: _answered || resultOpen
                  ? null
                  : () => _pick(option.word))),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctRhyme),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
