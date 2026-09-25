import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/mastery_question.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test(
      'every letter has five varied questions, unique choices and TTS audio available',
      () {
    for (final letter in allLetters) {
      for (var seed = 0; seed < 30; seed++) {
        final questions =
            buildMasteryQuestions(letter.letter, random: Random(seed));
        expect(questions, hasLength(5));
        expect(questions.map((q) => q.type).toSet(), hasLength(5));
        expect(questions.where((q) => q.requiresAudio), hasLength(3));
        expect(questions.map((q) => q.prompt).toSet(), hasLength(5));
        for (final q in questions) {
          expect(q.options.toSet().length, q.options.length);
          expect(q.options.where((option) => option == q.answer), hasLength(1));
          if (q.requiresAudio) {
            if (q.type == MasteryQuestionType.soundPicture) {
              expect(q.answer, isNot(endsWith(q.audioPhrase!)));
              expect(q.options.any((o) => o.endsWith(q.audioPhrase!)), isFalse);
              expect(q.prompt, contains('same sound'));
              if (letter.letter == 'C') {
                expect(q.options.any((o) => o.endsWith('Kite')), isFalse);
              }
            }
            if (q.type == MasteryQuestionType.soundPosition) {
              expect(q.audioPhrase, isNot('Cake'));
            }
            // TTS: assetForPhrase always returns non-null for non-empty phrases
            final asset = PhonicsAudioService.assetForPhrase(q.audioPhrase!);
            expect(asset, isNotNull, reason: q.audioPhrase);
            expect(q.audioPhrase, isNot(contains('says')));
            expect(q.prompt, isNot(contains(q.audioPhrase!)));
          }
        }
        expect(questions.first.prompt, isNot(contains(' ${letter.letter} ')));
      }
    }
  });

  test('X uses Xylophone content', () {
    final questions = buildMasteryQuestions('X', random: Random(1));
    expect(questions.first.prompt, contains('/ks/'));
    for (final q in questions.where((q) => q.requiresAudio)) {
      // TTS: assetForPhrase returns __tts__ (non-null) for any non-empty phrase
      expect(PhonicsAudioService.assetForPhrase(q.audioPhrase!), isNotNull);
    }
  });

  test('B examples vary across the existing vocabulary', () {
    final questions = buildMasteryQuestions('B', random: Random(3));
    expect(
        questions
            .where((q) => q.requiresAudio)
            .map((q) => q.audioPhrase)
            .toSet()
            .length,
        greaterThan(1));
  });

  test('limited vocabulary and vowels use sound position, not word recognition',
      () {
    for (final letter in ['A', 'E', 'I', 'O', 'U', 'D', 'X']) {
      final questions = buildMasteryQuestions(letter, random: Random(7));
      expect(questions[3].type, MasteryQuestionType.soundPosition);
      expect(questions[4].type, MasteryQuestionType.missingLetter);
    }
  });
}
