import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../data/phonics_activity_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

import 'sound_match_screen.dart';
import 'memory_game_screen.dart';
import 'phonics_quiz_screen.dart';
import 'word_builder_screen.dart';
import 'voice_recognition_screen.dart';
import 'alphabet_order_screen.dart';
import 'missing_vowel_screen.dart';
import 'picture_word_match_screen.dart';
import 'sound_position_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool _opening = false;
  Future<void> _play(String title, Widget Function(Difficulty) builder,
      String Function(Difficulty) detail) async {
    if (_opening || !context.read<AppProvider>().gameAccess) {
      return;
    }
    setState(() => _opening = true);
    try {
      final difficulty = await chooseGameDifficulty(context, title, detail);
      if (!mounted ||
          difficulty == null ||
          !context.read<AppProvider>().gameAccess) {
        return;
      }
      await LearnerNavigation.open(context, builder(difficulty));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _card(
          String title,
          String description,
          IconData icon,
          Widget Function(Difficulty) builder,
          String Function(Difficulty) detail) =>
      LearnerActivityCard(
          accent: switch (title) {
            'Sound Match' ||
            'Word Builder' ||
            'Picture Match' =>
              const Color(0xFF167769),
            'Memory Flip' ||
            'Alphabet Order' ||
            'Sound Position' =>
              const Color(0xFFB45731),
            _ => const Color(0xFF7052CA),
          },
          title: title,
          description: description,
          icon: icon,
          onPressed: _opening ? null : () => _play(title, builder, detail));
  @override
  Widget build(BuildContext context) {
    if (!context.watch<AppProvider>().gameAccess) {
      return const LearnerPage(
          title: 'Game Zone', child: Text('Games are turned off by a parent.'));
    }
    return LearnerPage(
        title: 'Game Zone',
        child: Column(children: [
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Little challenges. Big discoveries!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          const MascotGuide(message: 'Pick a game and give it a go.'),
          const SizedBox(height: 20),
          _card(
              'Sound Match',
              'Match word sounds with letters.',
              Icons.hearing,
              (d) => SoundMatchScreen(difficulty: d),
              (d) =>
                  '${soundRoundsForDifficulty(d).length} rounds · ${soundRoundsForDifficulty(d).first.options.length} choices'),
          _card(
              'Memory Flip',
              'Match letters to word pictures.',
              Icons.grid_view,
              (d) => MemoryGameScreen(difficulty: d),
              (d) => '${memoryPairsForDifficulty(d).length} pairs'),
          _card(
              'Phonics Quiz',
              'Listen and choose the matching letters.',
              Icons.quiz_outlined,
              (d) => PhonicsQuizScreen(difficulty: d),
              (d) => '${quizQuestionsForDifficulty(d).length} questions'),
          _card(
              'Word Builder',
              'Fill the blanks to complete the word.',
              Icons.extension_outlined,
              (d) => WordBuilderScreen(difficulty: d),
              (d) =>
                  '${wordPuzzlesForDifficulty(d).length} words · ${wordPuzzlesForDifficulty(d).first.correctLetters.length} blanks in the first word'),
          _card(
              'Speak & Recognize',
              'Say the word aloud.',
              Icons.mic_none,
              (d) => VoiceRecognitionScreen(difficulty: d),
              (d) => '${voiceWords[d]!.length} words'),
          _card(
              'Alphabet Order',
              'Tap letters in alphabetical order.',
              Icons.sort_by_alpha,
              (d) => AlphabetOrderScreen(difficulty: d),
              (d) => switch (d) {
                    Difficulty.easy => 'A–F · 6 letters',
                    Difficulty.medium => 'A–M · 13 letters',
                    Difficulty.hard => 'A–Z · 26 letters'
                  }),
          _card(
              'Missing Vowel',
              'Choose the missing vowel.',
              Icons.text_fields,
              (d) => MissingVowelScreen(difficulty: d),
              (d) => '${vowelPuzzlesFor(d).length} words'),
          _card(
              'Picture Match',
              'Match the word to its picture.',
              Icons.image_outlined,
              (d) => PictureWordMatchScreen(difficulty: d),
              (d) =>
                  '${pictureRoundsFor(d).length} words · ${pictureRoundsFor(d).first.options.length} pictures'),
          _card(
              'Sound Position',
              'Find where you hear the sound.',
              Icons.spatial_audio_off,
              (d) => SoundPositionScreen(difficulty: d),
              (d) =>
                  '${positionRoundsFor(d).length} words · ${positionRoundsFor(d).first.options.length} positions'),
        ]));
  }
}
