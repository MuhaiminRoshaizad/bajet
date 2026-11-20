import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/domain/coach_tidy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashes become commas, and a range of numbers reads "to"', () {
    expect(tidyReply('Food — mostly lunch — came to RM96.10', emoji: 1), 'Food, mostly lunch, came to RM96.10');
    expect(tidyReply('3–5 days left', emoji: 1), '3 to 5 days left');
    expect(tidyReply('a long-term goal', emoji: 1), 'a long-term goal', reason: 'hyphens stay');
  });

  test('a stock opener or closer that slipped through goes', () {
    expect(tidyReply("Great question! You're RM22.40 over.", emoji: 0), "You're RM22.40 over.");
    expect(tidyReply("food is RM96.10 of it. You've got this! 💪", emoji: 1), 'food is RM96.10 of it.');
    expect(tidyReply('cook till sunday. Let me know if you want a breakdown!', emoji: 0), 'cook till sunday.');
  });

  test('emoji past the limit are dropped, the first kept', () {
    expect(tidyReply('wah 😱💸 over by RM22.40 📉', emoji: 1), 'wah 😱 over by RM22.40');
    expect(tidyReply('i saw that 😉', emoji: 0), 'i saw that');
    expect(tidyReply('nice 👍🏽 week', emoji: 0), 'nice week');
  });

  test('message breaks survive, and a reply that would be left empty is kept as it came', () {
    expect(tidyReply('wah RM172.40\n<next>\nfood is most of it', emoji: 1), 'wah RM172.40\n<next>\nfood is most of it');
    expect(tidyReply('Sure!', emoji: 0), 'Sure!');
  });

  test('bajety may have one emoji, Strict, Professional and Sees Everything none, the rest one', () {
    expect(emojiLimit(CoachFace.bajety, CoachPersonality.strict), 1);
    expect(emojiLimit(CoachFace.aina, CoachPersonality.strict), 0);
    expect(emojiLimit(CoachFace.mei, CoachPersonality.professional), 0);
    expect(emojiLimit(CoachFace.hafiz, CoachPersonality.seesEverything), 0);
    expect(emojiLimit(CoachFace.aina, CoachPersonality.roaster), 1);
  });
}
