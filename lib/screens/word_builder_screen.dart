// lib/screens/word_builder_screen.dart
//
// Puzzle order randomised every session via GameRoundRandomizer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';

class WordBuilderScreen extends StatefulWidget {
  final Difficulty difficulty;
  const WordBuilderScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with GameSessionUi<WordBuilderScreen> {
  late List<WordPuzzle> _activePuzzles;
  int _puzzleIndex = 0;
  bool? _feedback;

  int _activeBlankIndex = 0;
  late List<String?> _filledAnswers;
  bool _busy = false;
  bool _allCorrect = false;
  late List<String> _shuffledTiles;

  WordPuzzle get _puzzle => _activePuzzles[_puzzleIndex];
  int get _blankCount => _puzzle.correctLetters.length;

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  void _buildSession() {
    final all = wordPuzzlesForDifficulty(widget.difficulty);
    final indices = GameRoundRandomizer()
        .nextSession('word_builder', widget.difficulty, all.length);
    _activePuzzles = indices.map((i) => all[i]).toList();
    _puzzleIndex = 0;
    _initPuzzle();
  }

  void _initPuzzle() {
    _activeBlankIndex = 0;
    _filledAnswers = List<String?>.filled(_blankCount, null);
    _allCorrect = false;
    _feedback = null;
    _shuffledTiles = List<String>.from(_puzzle.tiles)..shuffle();
  }

  void _tapTile(String letter) async {
    if (_allCorrect || _busy || resultOpen) return;
    _busy = true;
    if (_activeBlankIndex >= _blankCount) return;

    final provider = context.read<AppProvider>();
    provider.audio.playTap();

    final isCorrect = letter == _puzzle.correctLetters[_activeBlankIndex];
    recordGameAnswer(correct: isCorrect);
    setState(() => _feedback = isCorrect);

    if (isCorrect) {
      setState(() {
        _filledAnswers[_activeBlankIndex] = letter;
        _activeBlankIndex++;
        if (_activeBlankIndex >= _blankCount) _allCorrect = true;
      });
      if (_allCorrect) {
        provider.audio.playCorrect();
        awardGameXp((10 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        if (_puzzleIndex < _activePuzzles.length - 1) {
          setState(() {
            _puzzleIndex++;
            _initPuzzle();
          });
        } else {
          _showWinDialog();
        }
      } else {
        provider.audio.playCorrect();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else {
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _restart() => setState(_buildSession);

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((15 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    showGameResult(_restart);
  }

  Widget _buildWordRow() {
    var blank = 0;
    final word = _puzzle.blanks
        .map((letter) => letter ?? (_filledAnswers[blank++] ?? '_'))
        .join(' ');
    return Text(word,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
      title: 'Word Builder',
      instructions:
          'Hear the word. Choose letters to fill the blanks from left to right.',
      difficulty: widget.difficulty,
      current: _puzzleIndex + 1,
      total: _activePuzzles.length,
      hasProgress: scoredAttempts > 0 && !resultOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
            child: GameImageCard(
                word: _puzzle.word[0] +
                    _puzzle.word.substring(1).toLowerCase())),
        const SizedBox(height: 16),
        _buildWordRow(),
        AudioButton(
            phrase:
                _puzzle.word[0] + _puzzle.word.substring(1).toLowerCase()),
        const SizedBox(height: 16),
        ..._shuffledTiles.map((letter) => GameAnswerButton(
            label: letter,
            onPressed: _allCorrect || _busy || resultOpen
                ? null
                : () => _tapTile(letter))),
        if (_feedback != null) GameFeedback(correct: _feedback!),
      ]));
}
