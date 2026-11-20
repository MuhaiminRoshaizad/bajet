import 'coach_settings.dart';

/// How many emoji one reply may carry: bajety one, the playful voices one,
/// and Strict, Professional and Sees Everything none.
int emojiLimit(CoachFace face, CoachPersonality personality) {
  if (face == CoachFace.bajety) return 1;
  return switch (personality) {
    CoachPersonality.strict || CoachPersonality.professional || CoachPersonality.seesEverything => 0,
    _ => 1,
  };
}

final _numberRange = RegExp(r'(\d)\s*[–—]\s*(\d)');
final _dash = RegExp(r'\s*(—|–|--)\s*');
final _opener = RegExp(r"^(great question|good question|sure thing|sure|of course|certainly|absolutely)[!.,]+\s*", caseSensitive: false);
final _closer = RegExp(r"(\s*(hope this helps|let me know if[^.!?\n]*|you've got this|you got this)[.!]*)+$", caseSensitive: false);

/// [reply] with the habits the coach is told to avoid taken out where they
/// slipped through: dashes become commas, a stock opener or closer goes
/// (with any emoji that ends it), and emoji past [emoji] are dropped. A
/// reply left empty is kept as it came.
String tidyReply(String reply, {required int emoji}) {
  var text = reply.replaceAllMapped(_numberRange, (m) => '${m[1]} to ${m[2]}').replaceAll(_dash, ', ');
  text = text.replaceFirst(_opener, '');
  final body = _withoutTrailingEmoji(text);
  if (_closer.hasMatch(body)) text = body.replaceFirst(_closer, '');
  text = _keepEmoji(text, emoji).trim();
  return text.isEmpty ? reply : text;
}

/// A picture character that starts an emoji.
bool _pictograph(int r) => ((r >= 0x1F000 && r <= 0x1FAFF) || (r >= 0x2600 && r <= 0x27BF) || (r >= 0x2B00 && r <= 0x2BFF)) && !_joins(r);

/// What follows a picture within one emoji: a variation, a skin tone or a
/// joiner to the next picture.
bool _joins(int r) => r == 0xFE0F || r == 0x200D || (r >= 0x1F3FB && r <= 0x1F3FF);

/// [text] with only its first [limit] emoji, each dropped with the space
/// before it.
String _keepEmoji(String text, int limit) {
  final runes = text.runes.toList();
  final out = <int>[];
  var kept = 0;
  for (var i = 0; i < runes.length; i++) {
    if (!_pictograph(runes[i])) {
      out.add(runes[i]);
      continue;
    }
    var end = i + 1;
    while (end < runes.length && (_joins(runes[end]) || (runes[end - 1] == 0x200D && _pictograph(runes[end])))) {
      end++;
    }
    if (kept++ < limit) {
      out.addAll(runes.sublist(i, end));
    } else if (out.isNotEmpty && out.last == 0x20) {
      out.removeLast();
    }
    i = end - 1;
  }
  return String.fromCharCodes(out);
}

/// [text] without the emoji and spaces that end it.
String _withoutTrailingEmoji(String text) {
  final runes = text.runes.toList();
  var end = runes.length;
  while (end > 0 && (runes[end - 1] == 0x20 || _pictograph(runes[end - 1]) || _joins(runes[end - 1]))) {
    end--;
  }
  return String.fromCharCodes(runes.sublist(0, end));
}
