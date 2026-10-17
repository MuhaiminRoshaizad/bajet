import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/insights.dart';
import 'insights_providers.dart';

/// Week, month or everything, and under week or month an arrow row that
/// steps back through earlier ones as far as the first day logged. Insights
/// and the report both pick their range with it.
class PeriodPicker extends ConsumerWidget {
  const PeriodPicker({super.key, required this.range, required this.onChanged});

  final InsightsRange range;
  final ValueChanged<InsightsRange> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final first = ref.watch(insightsFirstDayProvider) ?? today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<InsightsPeriod>(
          segments: const [
            ButtonSegment(value: InsightsPeriod.week, label: Text('Week')),
            ButtonSegment(value: InsightsPeriod.month, label: Text('Month')),
            ButtonSegment(value: InsightsPeriod.all, label: Text('All')),
          ],
          selected: {range.period},
          showSelectedIcon: false,
          // Switching always lands on the current week or month.
          onSelectionChanged: (s) => onChanged((period: s.single, offset: 0)),
        ),
        const SizedBox(height: AppSpacing.s),
        range.period == InsightsPeriod.all
            ? SizedBox(
                height: 52,
                child: Center(child: Text('Everything since ${Dates.full(first)}', style: TextStyle(color: context.colors.muted, fontSize: 13))),
              )
            : _Stepper(range: range, today: today, first: first, onChanged: onChanged),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.range, required this.today, required this.first, required this.onChanged});

  final InsightsRange range;
  final DateTime today;
  final DateTime first;
  final ValueChanged<InsightsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final week = range.period == InsightsPeriod.week;
    final current = range.offset == 0;
    var (from, to) = periodSpan(range.period, today, first, offset: range.offset);
    if (from.isBefore(first)) from = first;
    final title = week ? Dates.span(from, to) : Dates.monthYear(DateTime.utc(today.year, today.month + range.offset));
    final unit = week ? 'week' : 'month';
    final note = current ? (week ? 'This week · so far' : '${Dates.span(from, to)} · so far') : 'Back to this $unit';
    void go(int offset) => onChanged((period: range.period, offset: offset));

    return SoftWell(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: range.offset > earliestOffset(range.period, today, first) ? () => go(range.offset - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Earlier $unit',
          ),
          Expanded(
            child: Semantics(
              button: !current,
              label: current ? '$title, ${note.replaceAll(' · ', ', ')}' : '$title. Back to this $unit',
              excludeSemantics: true,
              child: InkWell(
                onTap: current ? null : () => go(0),
                borderRadius: BorderRadius.circular(AppRadii.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  // The label cross-fades as the range changes.
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Column(
                      key: ValueKey(range),
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: current ? c.muted : c.primary, fontWeight: current ? FontWeight.w400 : FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: current ? null : () => go(range.offset + 1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Later $unit',
          ),
        ],
      ),
    );
  }
}

/// Slides [child] in from the side its range came from whenever [range]
/// changes: from the left going back, from the right going forward.
class PeriodSlide extends StatefulWidget {
  const PeriodSlide({super.key, required this.range, required this.child});

  final InsightsRange range;
  final Widget child;

  @override
  State<PeriodSlide> createState() => _PeriodSlideState();
}

class _PeriodSlideState extends State<PeriodSlide> with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(vsync: this, duration: AppMotion.fast, value: 1);
  late final _eased = CurvedAnimation(parent: _slide, curve: AppMotion.ease);
  var _from = 0.0;

  @override
  void didUpdateWidget(PeriodSlide old) {
    super.didUpdateWidget(old);
    if (old.range == widget.range || MediaQuery.disableAnimationsOf(context)) return;
    final back = old.range.period == widget.range.period && widget.range.offset < old.range.offset;
    _from = back ? -24 : 24;
    _slide.forward(from: 0);
  }

  @override
  void dispose() {
    _eased.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _eased,
        builder: (context, child) => Opacity(
          opacity: _eased.value,
          child: Transform.translate(offset: Offset(_from * (1 - _eased.value), 0), child: child),
        ),
        child: widget.child,
      );
}
