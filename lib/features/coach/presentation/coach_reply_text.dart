import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/reply_format.dart';

/// A reply from the coach as it reads, not as it was typed: bold and italic
/// where the coach marked them, headings as bold lines, and lists with real
/// bullets or numbers hanging beside their wrapped lines. It can be selected
/// and copied as one, without the marks.
class CoachReplyText extends StatelessWidget {
  const CoachReplyText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final blocks = parseReply(text);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, b) in blocks.indexed)
            Padding(
              // Items of one list sit close; anything else gets a paragraph's gap.
              padding: EdgeInsets.only(top: i == 0 ? 0 : (_isItem(b) && _isItem(blocks[i - 1]) ? AppSpacing.xs : AppSpacing.s)),
              child: _block(context, b),
            ),
        ],
      ),
    );
  }

  static bool _isItem(ReplyBlock b) => b.kind == ReplyBlockKind.bullet || b.kind == ReplyBlockKind.numbered;

  Widget _block(BuildContext context, ReplyBlock b) {
    final words = Text.rich(TextSpan(children: [
      for (final r in b.runs)
        TextSpan(text: r.text, style: TextStyle(fontWeight: r.bold ? FontWeight.w800 : null, fontStyle: r.italic ? FontStyle.italic : null)),
    ]), style: style);
    if (!_isItem(b)) return words;
    final marker = b.kind == ReplyBlockKind.bullet ? '•' : '${b.number}.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: b.kind == ReplyBlockKind.bullet ? 16 : 22, child: Text(marker, style: style.copyWith(color: context.colors.muted))),
        Expanded(child: words),
      ],
    );
  }
}
