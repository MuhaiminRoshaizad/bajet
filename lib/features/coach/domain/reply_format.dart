/// A stretch of a reply's text drawn one way.
class ReplyRun {
  const ReplyRun(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) => other is ReplyRun && other.text == text && other.bold == bold && other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() => '${bold ? '**' : ''}${italic ? '_' : ''}$text${italic ? '_' : ''}${bold ? '**' : ''}';
}

enum ReplyBlockKind { paragraph, heading, bullet, numbered }

/// One paragraph, heading or list item of a reply.
class ReplyBlock {
  const ReplyBlock(this.kind, this.runs, {this.number});

  final ReplyBlockKind kind;
  final List<ReplyRun> runs;

  /// A numbered item's own number, as the coach wrote it.
  final String? number;

  String get text => runs.map((r) => r.text).join();
}

final _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
final _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
final _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
final _quote = RegExp(r'^\s*>\s?');
final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');

/// Reads the Markdown the coach writes into what the chat draws: paragraphs,
/// headings as bold lines, bulleted and numbered items, with bold and italic
/// runs inside. Links, code, quotes and rules keep their words and lose their
/// marks, so nothing shows as raw syntax. Only the look changes: every word
/// the coach wrote is kept.
List<ReplyBlock> parseReply(String text) {
  final blocks = <ReplyBlock>[];
  final paragraph = <String>[];
  void endParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(ReplyBlock(ReplyBlockKind.paragraph, parseRuns(paragraph.join('\n'))));
    paragraph.clear();
  }

  for (final raw in text.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.replaceFirst(_quote, '');
    if (line.trim().isEmpty || _rule.hasMatch(line)) {
      endParagraph();
    } else if (_heading.firstMatch(line) case final h?) {
      endParagraph();
      blocks.add(ReplyBlock(ReplyBlockKind.heading, [for (final r in parseRuns(h[1]!)) ReplyRun(r.text, bold: true, italic: r.italic)]));
    } else if (_bullet.firstMatch(line) case final b?) {
      endParagraph();
      blocks.add(ReplyBlock(ReplyBlockKind.bullet, parseRuns(b[1]!)));
    } else if (_numbered.firstMatch(line) case final n?) {
      endParagraph();
      blocks.add(ReplyBlock(ReplyBlockKind.numbered, parseRuns(n[2]!), number: n[1]));
    } else {
      paragraph.add(line.trimRight());
    }
  }
  endParagraph();
  return blocks;
}

final _inline = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])|`([^`]+)`|\[([^\]]+)\]\([^)]*\)');

/// The bold and italic runs of one block's text. An asterisk that opens
/// nothing, such as "5 * 3", stays as it is.
List<ReplyRun> parseRuns(String text) {
  final runs = <ReplyRun>[];
  var at = 0;
  for (final m in _inline.allMatches(text)) {
    if (m.start > at) runs.add(ReplyRun(text.substring(at, m.start)));
    if (m[1] != null || m[2] != null) {
      // Bold may hold italics of its own.
      for (final r in parseRuns(m[1] ?? m[2]!)) {
        runs.add(ReplyRun(r.text, bold: true, italic: r.italic));
      }
    } else if (m[3] != null) {
      runs.add(ReplyRun(m[3]!, italic: true));
    } else {
      runs.add(ReplyRun(m[4] ?? m[5]!));
    }
    at = m.end;
  }
  if (at < text.length) runs.add(ReplyRun(text.substring(at)));
  return runs;
}
