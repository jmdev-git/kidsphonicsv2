import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'open every A-Z lesson: consistent text and correctly named audio buttons',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: const MaterialApp(home: LetterSoundsScreen())));
    for (final letter in allLetters) {
      await tester.pump();
      expect(find.text('${letter.letter} ${letter.lowercase}'), findsOneWidget);
      expect(find.text(letter.sound), findsOneWidget);
      expect(find.text(letter.example), findsOneWidget);
      expect(find.text('Hear Letter'), findsOneWidget);
      expect(find.text('Hear Word'), findsOneWidget);
      expect(find.text('Hear Sound'), findsNothing);
      expect(p.getLetterProgress(letter.letter).mastered, isFalse);
      expect(p.getLetterProgress(letter.letter).attempts, 0);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Next →'));
      await tester.tap(find.text('Next →'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });

  testWidgets('vowels view clearly identifies its short-vowel scope',
      (tester) async {
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: LetterSoundsScreen(vowelsOnly: true))));
    expect(find.text('Short Vowel Sounds'), findsOneWidget);
    expect(find.textContaining('Ice Cream'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });
}
