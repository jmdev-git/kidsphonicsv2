import '../widgets/mascot_guide.dart';
import '../models/learning_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/learning_progress_widgets.dart';
import '../theme/kids_ui.dart';
import 'letter_mastery_check_screen.dart';

class LetterSoundsScreen extends StatefulWidget {
  final bool vowelsOnly;
  const LetterSoundsScreen({super.key, this.vowelsOnly = false});
  @override
  State<LetterSoundsScreen> createState() => _LetterSoundsScreenState();
}

class _LetterSoundsScreenState extends State<LetterSoundsScreen> {
  int _currentIndex = 0;
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();
  AppProvider? _provider;
  List<LetterItem> get _letters => widget.vowelsOnly
      ? allLetters
          .where((l) => const ['A', 'E', 'I', 'O', 'U'].contains(l.letter))
          .toList()
      : allLetters;
  LetterItem get _current => _letters[_currentIndex];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().markLetterViewed(_current.letter);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    _provider?.phonicsAudio.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    _provider?.phonicsAudio.stop();
    setState(() => _currentIndex = index);
    context.read<AppProvider>().markLetterViewed(_current.letter);
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final status = provider.getLetterStatus(_current.letter);
    return LearnerPage(
        title: widget.vowelsOnly ? 'Short Vowel Sounds' : 'Letter Sounds',
        scrollController: _scroll,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const MascotGuide(
              mascot: LearningMascot.wigloo,
              message:
                  'Let’s explore! Listen to the letter and its sound, then try the practice.'),
          const SizedBox(height: 16),
          Text('Letter ${_currentIndex + 1} of ${_letters.length}',
              textAlign: TextAlign.center),
          Text('${_current.letter} ${_current.lowercase}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: KidsUi.ink)),
          Center(
              child: GameImageCard(
                  size: 200,
                  word: _current.word,
                  label: _current.example)),
          const SizedBox(height: 16),
          Text(_current.example,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(_current.sound,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20)),
          Center(child: LearningStatusBadge(status: status)),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                AudioButton(
                    key: ValueKey('letter-${_current.letter}'),
                    phrase: _current.letterAudioKey,
                    label: 'Hear Letter'),
                if (_current.soundAudioKey != null)
                  AudioButton(
                      key: ValueKey('sound-${_current.letter}'),
                      phrase: _current.soundAudioKey!,
                      label: 'Hear Sound'),
                AudioButton(
                    key: ValueKey('word-${_current.letter}'),
                    phrase: _current.wordAudioKey,
                    label: 'Hear Word'),
              ]),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: () async {
                await provider.phonicsAudio.stop();
                if (!context.mounted) return;
                await LearnerNavigation.open(
                    context, LetterMasteryCheckScreen(letter: _current));
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Practice This Letter')),
          const SizedBox(height: 16),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                    onPressed: () => _select(
                        (_currentIndex - 1 + _letters.length) %
                            _letters.length),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous')),
                OutlinedButton(
                    onPressed: () => Scrollable.ensureVisible(
                        _gridKey.currentContext!,
                        duration: const Duration(milliseconds: 180)),
                    child: Text(widget.vowelsOnly ? 'Vowel Grid' : 'A–Z Grid')),
                OutlinedButton(
                    onPressed: () =>
                        _select((_currentIndex + 1) % _letters.length),
                    child: const Text('Next →')),
              ]),
          const SizedBox(height: 24),
          Text('Choose a letter',
              key: _gridKey,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(
              builder: (_, box) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _letters.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (box.maxWidth / 80).floor().clamp(3, 6),
                      mainAxisExtent: 88,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8),
                  itemBuilder: (_, i) {
                    final letter = _letters[i];
                    final s = provider.getLetterStatus(letter.letter);
                    return Semantics(
                        label: 'Choose letter ${letter.letter}, ${s.label}',
                        selected: i == _currentIndex,
                        child: OutlinedButton(
                            onPressed: () => _select(i),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                backgroundColor:
                                    s.color.withValues(alpha: .12)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(letter.letter,
                                      style: const TextStyle(fontSize: 28)),
                                  Icon(s.icon,
                                      color: s == LearningStatus.mastered
                                          ? KidsUi.correct
                                          : KidsUi.ink,
                                      size: 20),
                                ])));
                  })),
        ]));
  }
}
