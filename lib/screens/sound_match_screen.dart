// lib/screens/sound_match_screen.dart
//
// Round order randomised every session via GameRoundRandomizer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class SoundMatchScreen extends StatefulWidget {
  final Difficulty difficulty;
  const SoundMatchScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen>
    with GameSessionUi<SoundMatchScreen> {
  late List<SoundRound> _activeRounds;
  int _roundIndex = 0;
  Map<String, bool?> _picks = {};
  bool _roundDone = false;
  late List<String> _opts;

  SoundRound get _round => _activeRounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = soundRoundsForDifficulty(widget.difficulty);
    final indices = GameRoundRandomizer()
        .nextSession('sound_match', widget.difficulty, all.length);
    _activeRounds = indices.map((i) => all[i]).toList();
    _roundIndex = 0;
    _picks = {};
    _roundDone = false;
    _opts = List<String>.from(_round.options)..shuffle();
  }

  void _nextRound() {
    if (_roundIndex < _activeRounds.length - 1) {
      setState(() {
        _roundIndex++;
        _picks = {};
        _roundDone = false;
        _opts = List<String>.from(_round.options)..shuffle();
      });
    } else {
      _showWinDialog();
    }
  }

  void _restart() => setState(_buildSession);

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((10 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    showGameResult(_restart, backLabel: 'Back to Games');
  }

  void _pick(String letter) async {
    if (_roundDone || _picks.values.contains(false) || resultOpen) return;
    if (_picks[letter] == true) return;

    final isCorrect = letter == _round.correctLetter;
    setState(() {
      _picks[letter] = isCorrect;
      if (isCorrect) _roundDone = true;
    });
    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      provider.audio.playCorrect();
      awardGameXp((5 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _nextRound();
    } else {
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _picks.remove(letter));
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'Sound Match',
        instructions:
            'Listen to the word. Choose the matching letter or letters.',
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
          Text(_round.question,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(phrase: _round.voiceHint),
          const SizedBox(height: KidsUi.section),
          ..._opts.map((option) => GameAnswerButton(
              label: letterChoiceLabel(option),
              selected: _picks[option] != null,
              result: _picks[option],
              onPressed:
                  _roundDone || _picks.values.contains(false) || resultOpen
                      ? null
                      : () => _pick(option))),
          if (_picks.isNotEmpty) GameFeedback(correct: _roundDone),
        ]),
      );
}
