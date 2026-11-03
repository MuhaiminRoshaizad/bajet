import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/coach_settings.dart';
import 'coach_avatar.dart';

/// A quoted line as the coach wrote it: whatever comes before a colon, such
/// as a bill's name, in bold. At most two lines.
class QuoteText extends StatelessWidget {
  const QuoteText(this.quote, {super.key, required this.style});

  final String quote;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final line = quote.replaceAll('\n', ' ');
    final cut = line.indexOf(':');
    // A colon far into the line is part of a sentence, not a label.
    final label = cut > 0 && cut < 40;
    return Text.rich(
      TextSpan(children: [
        if (label) TextSpan(text: line.substring(0, cut + 1), style: const TextStyle(fontWeight: FontWeight.w800)),
        TextSpan(text: label ? line.substring(cut + 1) : line),
      ]),
      style: style,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The question box while replying: the quote and the field become one
/// piece with a soft glow, the quote springing up into place. Without a
/// [quote] it is just the field.
class ReplyBox extends StatelessWidget {
  const ReplyBox({super.key, required this.quote, required this.face, required this.onCancel, required this.child});

  final String? quote;

  /// The coach being replied to, named and shown beside the quote.
  final CoachFace face;
  final VoidCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = quote;
    final still = MediaQuery.disableAnimationsOf(context);
    final time = still ? Duration.zero : AppMotion.enter;
    return AnimatedContainer(
      duration: time,
      curve: AppMotion.ease,
      decoration: q == null
          ? BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.transparent, width: 1.5))
          : BoxDecoration(
              color: c.well,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.primary.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.18), blurRadius: 18, spreadRadius: 1)],
            ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AnimatedSize(
          duration: time,
          curve: Curves.easeOutBack,
          alignment: Alignment.bottomCenter,
          child: q == null
              ? const SizedBox(width: double.infinity)
              : TweenAnimationBuilder<double>(
                  key: ValueKey(q),
                  tween: Tween(begin: still ? 1 : 0, end: 1),
                  duration: time,
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.s, AppSpacing.s, 0),
                    child: Container(
                      key: const ValueKey('reply-quote'),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.s, 0, AppSpacing.s),
                      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(
                          width: 3,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.primary, c.sphere.glow]),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        CoachAvatar(face: face, size: 28, animate: false, idle: false),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(Icons.reply_rounded, size: 14, color: c.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Replying to ${face.label}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            QuoteText(q, style: TextStyle(color: c.ink, fontSize: 13, height: 1.35)),
                          ]),
                        ),
                        IconButton(onPressed: onCancel, icon: Icon(Icons.close_rounded, size: 18, color: c.muted), tooltip: 'Cancel reply'),
                      ]),
                    ),
                  ),
                ),
        ),
        child,
      ]),
    );
  }
}

/// The quote carried inside a reply the user sent, above their words.
class SentQuote extends StatelessWidget {
  const SentQuote({super.key, required this.quote, required this.face});

  final String quote;
  final CoachFace? face;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.m, AppSpacing.s),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: c.onPrimary.withValues(alpha: 0.75), width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(face?.label ?? 'The coach', style: TextStyle(color: c.onPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
        QuoteText(quote, style: TextStyle(color: c.onPrimary.withValues(alpha: 0.85), fontSize: 13, height: 1.35)),
      ]),
    );
  }
}
