// lib/screens/sound_position_screen.dart
//
// Beginning / Middle / End Sound — shows a word + picture, asks where
// a given letter sound appears (Beginning, Middle, or End).
//
// Easy   : Beginning only (3 words)
// Medium : Beginning + End (5 words)
// Hard   : Beginning + Middle + End (7 words)
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

class SoundPositionScreen extends StatefulWidget {
  final Difficulty difficulty;
  const SoundPositionScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<SoundPositionScreen> createState() =>
      SoundPositionitionScreenState();
}

class SoundPositionitionScreenState extends State<SoundPositionScreen>
    with GameSessionUi<SoundPositionScreen> {
  late List<SoundPositionRound> _activeRounds;
  int _index = 0;
  SoundPosition? _picked;
  bool _answered = false;

  SoundPositionRound get _round => _activeRounds[_index];

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = positionRoundsFor(widget.difficulty);
    final indices = GameRoundRandomizer()
        .nextSession('sound_position', widget.difficulty, all.length);
    _activeRounds = indices.map((i) => all[i]).toList();
    _index = 0;
    _picked = null;
    _answered = false;
  }

  void _pick(SoundPosition pos) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = pos == _round.correctPos;
    setState(() => _picked = pos);

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
    if (_index < _activeRounds.length - 1) {
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
        title: 'Sound Position',
        instructions:
            'Listen to the word. Choose where you hear the sound.',
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
          Text(
              'Where is ${_round.soundDisplay} in ${_round.word}?',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase:
                  _round.word[0] + _round.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          ..._round.options.map((option) => GameAnswerButton(
              label: option.label,
              selected: _picked == option,
              result:
                  _picked == option ? option == _round.correctPos : null,
              onPressed: _answered || _picked != null || resultOpen
                  ? null
                  : () => _pick(option))),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctPos),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
