import 'package:bajet/features/coach/domain/coach_guard.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  test('the gatekeeper asks Haiku for one label as JSON, with thinking off', () async {
    final coach = FakeCoach()..gateKind = 'off_topic';
    expect(await gate(coach, 'test-key', 'write me a calculator in python'), GateKind.offTopic);
    final r = coach.gateRequests.single;
    expect((r.model, r.thinkingOff, r.maxTokens), ('claude-haiku-5-5', true, 64));
    expect(r.outputSchema, isNotNull);
    expect(r.messages.single['content'], 'write me a calculator in python');
    expect(coach.requests, isEmpty);
  });

  test('a repeat is the same words within a minute, whatever the case or spacing', () {
    expect(isRepeat('How did  this week go?', 'how did this week go?', const Duration(seconds: 20)), isTrue);
    expect(isRepeat('How did this week go?', 'How did this week go?', const Duration(minutes: 2)), isFalse);
    expect(isRepeat('How did this month go?', 'How did this week go?', Duration.zero), isFalse);
    expect(isRepeat('Hi', null, Duration.zero), isFalse);
  });

  test('code or an essay never shows as a reply', () {
    expect(replyLooksWrong('Here you go:\n```python\nprint(1)\n```'), isTrue);
    expect(replyLooksWrong('def add(a, b):\n    return a + b\nprint(add(1, 2))\nimport math'), isTrue);
    expect(replyTooLong('x' * (coachReplyLimit + 1)), isTrue);
    // A long, honest answer is still an answer.
    expect(replyLooksWrong('x' * 1600), isFalse);
    expect(replyTooLong('x' * 1600), isFalse);
    expect(replyLooksWrong('RM16.50 left this week; about RM8.25 a day. Keep Thursday light.'), isFalse);
  });

  test('every personality turns things down in its own voice, firmer each time', () {
    for (final p in CoachPersonality.values) {
      final lines = [for (var i = 0; i < 4; i++) declineLine(p, i)];
      expect(lines.take(3).toSet(), hasLength(3), reason: p.name);
      expect(lines[3], lines[2], reason: 'past the last line it stays there');
      expect({for (var i = 0; i < 3; i++) repeatLine(p, i)}, hasLength(3));
    }
    expect(declineLine(CoachPersonality.seesEverything, 0), endsWith('😉'));
  });
}
