// lib/screens/picture_word_match_screen.dart
//
// Picture-to-Word Match — 4 pictures shown, tap the one that matches the word.
// Tests word recognition by connecting written text to images.
//
// Easy   : 3 choices, simple 3-letter words
// Medium : 4 choices
// Hard   : 5 choices + longer words
//
// Round order randomised every session via GameRoundRandomizer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class PictureWordMatchScreen extends StatefulWidget {
  final Difficulty difficulty;
  const PictureWordMatchScreen(
      {super.key, this.difficulty = Difficulty.easy});

  @override
  State<PictureWordMatchScreen> createState() =>
      _PictureWordMatchScreenState();
}

class _PictureWordMatchScreenState extends State<PictureWordMatchScreen>
    with GameSessionUi<PictureWordMatchScreen> {
  late List<PictureWordRound> _activeRounds;
  int _index = 0;
  String? _picked;
  bool _answered = false;
  late List<int> _shuffledIdx;

  PictureWordRound get _round => _activeRounds[_index];

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = pictureRoundsFor(widget.difficulty);
    final indices = GameRoundRandomizer()
        .nextSession('picture_match', widget.difficulty, all.length);
    _activeRounds = indices.map((i) => all[i]).toList();
    _index = 0;
    _picked = null;
    _answered = false;
    _shuffleIdx();
  }

  void _shuffleIdx() {
    _shuffledIdx =
        List.generate(_round.options.length, (i) => i)..shuffle();
  }

  void _pick(String emoji) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = emoji == _round.correctEmoji;
    setState(() => _picked = emoji);

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() => _answered = true);
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    } else {
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_index < _activeRounds.length - 1) {
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
        _shuffleIdx();
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
        title: 'Picture Match',
        instructions: 'Read or hear the word. Tap its picture.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _activeRounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: GameImageCard(
                  word: _round.word[0] +
                      _round.word.substring(1).toLowerCase())),
          const SizedBox(height: KidsUi.padding),
          Text(_round.word,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase:
                  _round.word[0] + _round.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          ..._shuffledIdx.map((option) => GameAnswerButton(
              label: 'Picture ${option + 1}',
              visual: GameImageCard(
                  word: _round.labels[option],
                  label: _round.labels[option]),
              selected: _picked == _round.options[option],
              result: _picked == _round.options[option]
                  ? _round.options[option] == _round.correctEmoji
                  : null,
              onPressed: _answered || _picked != null || resultOpen
                  ? null
                  : () => _pick(_round.options[option]))),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctEmoji),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
