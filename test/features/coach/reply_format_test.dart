import 'package:bajet/features/coach/domain/reply_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bold labels lose their asterisks and keep every word', () {
    expect(parseRuns('**Balance:** RM2,140.50'), [const ReplyRun('Balance:', bold: true), const ReplyRun(' RM2,140.50')]);
    expect(parseRuns('The __Laptop__ goal'), [const ReplyRun('The '), const ReplyRun('Laptop', bold: true), const ReplyRun(' goal')]);
  });

  test('italics are drawn, and an asterisk that opens nothing stays', () {
    expect(parseRuns('That is *maybe* fine'), [const ReplyRun('That is '), const ReplyRun('maybe', italic: true), const ReplyRun(' fine')]);
    expect(parseRuns('5 * 3 is 15'), [const ReplyRun('5 * 3 is 15')]);
    expect(parseRuns('**really *very* tight**'), [
      const ReplyRun('really ', bold: true),
      const ReplyRun('very', bold: true, italic: true),
      const ReplyRun(' tight', bold: true),
    ]);
  });

  test('code and links keep their words and lose their marks', () {
    expect(parseRuns('Tap `Log it` or see [the plan](https://x.y)').map((r) => r.text).join(), 'Tap Log it or see the plan');
  });

  test('a reply reads as paragraphs, a bold heading, and bulleted and numbered items', () {
    final blocks = parseReply('''
Hi hi! Here's how things look:

## This week
- **Balance:** RM2,140.50
* **Spent:** RM0.00
1. Log lunch
2) Check the plan
Two lines
of one paragraph

---
> A quote''');
    expect([for (final b in blocks) b.kind], [
      ReplyBlockKind.paragraph,
      ReplyBlockKind.heading,
      ReplyBlockKind.bullet,
      ReplyBlockKind.bullet,
      ReplyBlockKind.numbered,
      ReplyBlockKind.numbered,
      ReplyBlockKind.paragraph,
      ReplyBlockKind.paragraph,
    ]);
    expect(blocks[1].runs.every((r) => r.bold), isTrue);
    expect(blocks[2].text, 'Balance: RM2,140.50');
    expect((blocks[4].number, blocks[5].number), ('1', '2'));
    expect(blocks[6].text, 'Two lines\nof one paragraph');
    expect(blocks[7].text, 'A quote');
  });

  test('a plain reply is one paragraph, exactly as written', () {
    final blocks = parseReply('You are on track.');
    expect(blocks.single.kind, ReplyBlockKind.paragraph);
    expect(blocks.single.runs, [const ReplyRun('You are on track.')]);
  });
}
