// lib/screens/alphabet_order_screen.dart
//
// Alphabet Order game: letters are shown shuffled — the child taps them
// in the correct A→Z order. Wrong tap shows a shake + red flash.
// Difficulty controls how many letters are in play:
//   Easy   → A–F  (6 letters)
//   Medium → A–M  (13 letters)
//   Hard   → A–Z  (26 letters)
//
// The displayed layout is reshuffled each session so the grid never
// looks the same twice, even though the correct tap-order is always A→Z.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

class AlphabetOrderScreen extends StatefulWidget {
  final Difficulty difficulty;
  const AlphabetOrderScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<AlphabetOrderScreen> createState() => _AlphabetOrderScreenState();
}

class _AlphabetOrderScreenState extends State<AlphabetOrderScreen>
    with GameSessionUi<AlphabetOrderScreen> {
  late List<String> _letters;   // sorted A→Z for this difficulty
  late List<String> _shuffled;  // randomised display order (changes each session)
  bool _busy = false;
  int _nextExpected = 0;
  Set<String> _correct = {};
  String? _wrongLetter;

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  List<String> _lettersForDifficulty() {
    const all = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    switch (widget.difficulty) {
      case Difficulty.easy:
        return all.substring(0, 6).split('');
      case Difficulty.medium:
        return all.substring(0, 13).split('');
      case Difficulty.hard:
        return all.split('');
    }
  }

  void _buildSession() {
    _letters = _lettersForDifficulty();
    // Shuffle the display layout — different grid arrangement every session
    _shuffled = List<String>.from(_letters)..shuffle();
    _nextExpected = 0;
    _correct = {};
    _wrongLetter = null;
    _busy = false;
  }

  void _restart() => setState(_buildSession);

  int get _totalLetters => _letters.length;
  bool get _finished => _correct.length == _totalLetters;

  void _tap(String letter) async {
    if (_finished || _busy || _correct.contains(letter)) return;
    setState(() => _busy = true);
    final provider = context.read<AppProvider>();

    recordGameAnswer(correct: letter == _letters[_nextExpected]);
    if (letter == _letters[_nextExpected]) {
      provider.audio.playCorrect();
      awardGameXp((3 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      setState(() {
        _correct.add(letter);
        _nextExpected++;
        _wrongLetter = null;
      });
      if (_finished) provider.recordActivityCompleted();
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      if (_finished) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          provider.audio.playWin();
          awardGameXp((15 * widget.difficulty.xpMultiplier).round());
          _showWinDialog();
        }
      }
    } else {
      provider.audio.playWrong();
      setState(() => _wrongLetter = letter);
      await Future.delayed(const Duration(milliseconds: 1300));
      if (mounted) setState(() => _wrongLetter = null);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    showGameResult(_restart);
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
      title: 'Alphabet Order',
      instructions: 'Tap the letters in alphabetical order. Start with A.',
      difficulty: widget.difficulty,
      current: _correct.length,
      total: _totalLetters,
      progressLabel: 'Letters placed',
      hasProgress: scoredAttempts > 0 && !resultOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            _finished
                ? 'Alphabet complete!'
                : 'Find ${_letters[_nextExpected]}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        LayoutBuilder(
            builder: (_, box) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _shuffled
                    .map((letter) => SizedBox(
                        width: (box.maxWidth - 16) / 3,
                        child: GameAnswerButton(
                            label: letter,
                            result: _correct.contains(letter)
                                ? true
                                : _wrongLetter == letter
                                    ? false
                                    : null,
                            onPressed: _busy ||
                                    _correct.contains(letter) ||
                                    resultOpen
                                ? null
                                : () => _tap(letter))))
                    .toList())),
        if (_wrongLetter != null) const GameFeedback(correct: false),
      ]));
}
