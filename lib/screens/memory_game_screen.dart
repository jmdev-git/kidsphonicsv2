// lib/screens/memory_game_screen.dart
//
// Pair order randomised every session via GameRoundRandomizer —
// different subset/order of pairs shown each time (Hard has 8 pairs,
// always shown in a fresh shuffled layout).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../services/game_round_randomizer.dart';
import '../widgets/learner_widgets.dart';

enum _CardType { letter, picture }

class _MemCard {
  final String id;
  final _CardType type;
  final String display;
  final String word;
  bool isFlipped = false;
  bool isMatched = false;

  _MemCard(
      {required this.id,
      required this.type,
      required this.display,
      required this.word});
}

class MemoryGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  const MemoryGameScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with GameSessionUi<MemoryGameScreen> {
  late List<_MemCard> _cards;
  List<_MemCard> _flipped = [];
  Set<String> _wrongCardIds = {};
  int _matchCount = 0;
  bool _locked = false;
  int _totalPairs = 0;

  @override
  void initState() {
    super.initState();
    _initCards();
  }

  void _initCards() {
    final allPairs = memoryPairsForDifficulty(widget.difficulty);
    // Randomise the order of pairs shown each session
    final indices = GameRoundRandomizer()
        .nextSession('memory', widget.difficulty, allPairs.length);
    final pairs = indices.map((i) => allPairs[i]).toList();

    final cards = <_MemCard>[];
    for (final p in pairs) {
      cards.add(_MemCard(
          id: p.letter,
          type: _CardType.letter,
          display: p.letter,
          word: p.word));
      cards.add(_MemCard(
          id: p.letter,
          type: _CardType.picture,
          display: p.emoji,
          word: p.word));
    }
    cards.shuffle();
    setState(() {
      _cards = cards;
      _flipped = [];
      _wrongCardIds = {};
      _matchCount = 0;
      _locked = false;
      _totalPairs = pairs.length;
    });
  }

  void _tapCard(_MemCard card) async {
    if (_locked || card.isFlipped || card.isMatched) return;
    final provider = context.read<AppProvider>();
    provider.audio.playFlip();
    setState(() {
      card.isFlipped = true;
      _flipped.add(card);
    });

    if (_flipped.length == 2) {
      _locked = true;
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;

      final a = _flipped[0], b = _flipped[1];
      final isMatch = a.id == b.id && a.type != b.type;
      recordGameAnswer(correct: isMatch);

      if (isMatch) {
        a.isMatched = true;
        b.isMatched = true;
        _matchCount++;
        provider.audio.playCorrect();
        awardGameXp((5 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        if (_matchCount == _totalPairs) {
          provider.recordActivityCompleted();
          provider.audio.playWin();
          awardGameXp((10 * widget.difficulty.xpMultiplier).round());
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) _showWinDialog();
        }
        if (!mounted) return;
        setState(() {
          _flipped = [];
          _locked = false;
        });
      } else {
        provider.audio.playWrong();
        final wrongA = a.id + a.type.name;
        final wrongB = b.id + b.type.name;
        if (!mounted) return;
        setState(() => _wrongCardIds = {wrongA, wrongB});
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          a.isFlipped = false;
          b.isFlipped = false;
          if (!mounted) return;
          setState(() {
            _wrongCardIds = {};
            _flipped = [];
            _locked = false;
          });
        }
      }
    }
  }

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    showGameResult(_initCards);
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'Memory Flip',
        instructions:
            'Turn over two cards. Match a letter with its word picture.',
        difficulty: widget.difficulty,
        current: _matchCount,
        total: _totalPairs,
        progressLabel: 'Pairs matched',
        hasProgress:
            (scoredAttempts > 0 || _flipped.isNotEmpty) && !resultOpen,
        child: LayoutBuilder(
            builder: (_, box) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cards.asMap().entries.map((entry) {
                  final card = entry.value;
                  final shown = card.isFlipped || card.isMatched;
                  return SizedBox(
                      width: (box.maxWidth - 8) / 2,
                      child: GameAnswerButton(
                        buttonKey: ValueKey('memory-${entry.key}'),
                        label: !shown
                            ? 'Turn over'
                            : card.type == _CardType.letter
                                ? card.display
                                : card.word,
                        visual: shown && card.type == _CardType.picture
                            ? GameImageCard(
                                word: card.word, label: card.word)
                            : null,
                        result: card.isMatched
                            ? true
                            : _wrongCardIds
                                    .contains(card.id + card.type.name)
                                ? false
                                : null,
                        onPressed: _locked ||
                                card.isMatched ||
                                card.isFlipped ||
                                resultOpen
                            ? null
                            : () => _tapCard(card),
                      ));
                }).toList())),
      );
}
