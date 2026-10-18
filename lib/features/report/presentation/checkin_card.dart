import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../opening/presentation/titanium_card.dart';
import '../domain/weekly_checkin.dart';

/// The check-in as a picture to share, in the app's own theme: the week's
/// spending against the allowance, its days as dots, fasting kept, money
/// found untracked and how the goal moved. Drawn at [size], a 4:5 portrait
/// that shares as 1080 × 1350 at three pixels a point. It is a picture, so
/// its text keeps its own size whatever the phone's text setting; the
/// preview scales the whole card instead.
class CheckinCard extends StatelessWidget {
  const CheckinCard({super.key, required this.w});

  final WeeklyCheckin w;

  static const size = Size(360, 450);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final goal = w.goal;
    final fasting = w.rules.where((r) => r.kind == RuleKind.fasting).toList();
    const figures = [FontFeature.tabularFigures()];
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: size.width,
        height: size.height,
        color: c.background,
        padding: const EdgeInsets.all(AppSpacing.xxl + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // A hairline keeps the graphite tile clear of a dark page.
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(28 * 16 / 56)),
                child: const AppIconTile(size: 28),
              ),
              const SizedBox(width: AppSpacing.s + 2),
              Expanded(child: Text('bajet · weekly check-in', style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w600))),
              Text('${Dates.short(w.monday)}–${Dates.short(w.sunday)}', style: TextStyle(color: c.muted, fontSize: 13, fontFeatures: figures)),
            ]),
            const Spacer(),
            Text(w.from == w.monday ? 'SPENT OF ALLOWANCE' : 'SPENT OF PLAN', style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: Money.format(w.spent), style: TextStyle(color: w.spent > w.plan ? c.bad : c.ink, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  TextSpan(text: '  / ${Money.format(w.plan)}', style: TextStyle(color: c.muted, fontSize: 20, fontWeight: FontWeight.w700)),
                ]),
                style: const TextStyle(fontFeatures: figures, height: 1),
              ),
            ),
            const Spacer(),
            Row(children: [for (final d in w.days) Expanded(child: _Dot(day: d))]),
            const Spacer(),
            Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
              if (fasting.isNotEmpty) _Chip('Fasting ${fasting.where((r) => r.kept).length} of ${fasting.length} kept'),
              _Chip('Untracked ${Money.format(w.untracked)}'),
              if (w.finished.isNotEmpty) _Chip('${w.withinPlan} of ${w.finished.length} days within plan'),
            ]),
            const Spacer(),
            if (goal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 2),
                decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.control)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(goal.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.primary, fontSize: 17, fontWeight: FontWeight.w800)),
                  Text(
                    [
                      '${w.daysToGo} ${w.daysToGo == 1 ? 'day' : 'days'} to go',
                      switch (w.change) {
                        null => 'baseline set',
                        final change => '${signedMoney(change)} ${change >= 0 ? 'closer' : 'further'} this week',
                      },
                    ].join(' · '),
                    style: TextStyle(color: c.primary, fontSize: 13, fontFeatures: figures),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// One day: filled when it kept to its plan, a ring when nothing was spent,
/// red when it went over, dashed while it is still today, and faint before
/// the first day or later in the week. A small mark tops a fasting day.
class _Dot extends StatelessWidget {
  const _Dot({required this.day});

  final CheckinDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final finished = day.state == CheckinDayState.finished;
    final decoration = switch (day.state) {
      CheckinDayState.today => BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.muted, width: 2)),
      CheckinDayState.noData || CheckinDayState.ahead => BoxDecoration(shape: BoxShape.circle, color: c.well),
      CheckinDayState.finished when day.over => BoxDecoration(shape: BoxShape.circle, color: c.bad),
      CheckinDayState.finished when day.spent == 0 => BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.good, width: 3.5)),
      CheckinDayState.finished => BoxDecoration(shape: BoxShape.circle, color: c.good),
    };
    return Column(children: [
      SizedBox.square(
        dimension: 30,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: DecoratedBox(decoration: decoration)),
          if (day.rule.isFastingDay && (finished || day.state == CheckinDayState.today))
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: c.keep, shape: BoxShape.circle, border: Border.all(color: c.background, width: 2)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: AppSpacing.xs + 2),
      Text(Dates.weekday(day.date), style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(color: c.well, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label, style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}
