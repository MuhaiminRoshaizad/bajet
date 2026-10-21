import 'package:bajet/features/coach/domain/coach_prompt.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime.utc(2026, 10, 21);

  test('the coach is told its own name, and that the coaches are never the user', () {
    final prompt = coachSystemPrompt(today, CoachPersonality.friendly, face: CoachFace.hafiz);
    expect(prompt, startsWith('You are Hafiz, the coach inside bajet'));
    expect(prompt, contains("bajety, Aina, Hafiz, Mei are the app's coaches, never the user"));
  });

  test('with no name given the coach uses none; with one it uses that and no other', () {
    expect(coachSystemPrompt(today, CoachPersonality.friendly), contains("You do not know the user's name, so do not call them by any name."));
    final named = coachSystemPrompt(today, CoachPersonality.friendly, userName: 'Sara');
    expect(named, contains('The user\'s name is "Sara". Use it now and then, and never call them anything else.'));
    expect(named, isNot(contains('You do not know')));
  });

  test('a name changes nothing else: every voice is word for word as before', () {
    for (final p in CoachPersonality.values) {
      expect(coachSystemPrompt(today, p, userName: 'Sara'), endsWith('Your voice: ${p.voice}'));
    }
  });
}
