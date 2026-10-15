import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/upcoming.dart';

/// Coming up as a month grid: each day with something planned carries a
/// dot, green for money in and ink for money out, and buy day is ringed.
/// Tapping a day lists what lands on it, drawn by [rowFor].
class UpcomingCalendar extends StatefulWidget {
  const UpcomingCalendar({super.key, required this.items, required this.today, required this.rowFor});

  final List<UpcomingItem> items;
  final DateTime today;
  final Widget Function(UpcomingItem item) rowFor;

  @override
  State<UpcomingCalendar> createState() => _UpcomingCalendarState();
}

class _UpcomingCalendarState extends State<UpcomingCalendar> {
  static final _monthTitle = DateFormat('MMMM yyyy');
  static final _dayName = DateFormat('EEEE d MMMM');
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Opens on the month of the first thing planned, not on an empty one.
  late DateTime _month = _monthOf(widget.items.map((i) => i.date).fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a) ?? widget.today);
  late DateTime? _selected = _firstPlannedIn(_month);

  static DateTime _monthOf(DateTime d) => DateTime.utc(d.year, d.month);

  DateTime get _lastMonth {
    final last = widget.items.map((i) => i.date).fold(widget.today, (a, b) => b.isAfter(a) ? b : a);
    return DateTime.utc(last.year, last.month);
  }

  DateTime get _firstMonth => DateTime.utc(widget.today.year, widget.today.month);

  List<UpcomingItem> _on(DateTime day) => [for (final i in widget.items) if (i.date == day) i];

  DateTime? _firstPlannedIn(DateTime month) {
    final days = [for (final i in widget.items) if (i.date.year == month.year && i.date.month == month.month) i.date]..sort();
    return days.firstOrNull;
  }

  void _go(int months) => setState(() {
        _month = DateTime.utc(_month.year, _month.month + months);
        _selected = _firstPlannedIn(_month);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final daysInMonth = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final lead = _month.weekday - 1;
    final selected = _selected;
    final picked = selected == null ? const <UpcomingItem>[] : _on(selected);
    final net = picked.fold(0, (s, i) => s + i.signedAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(onPressed: _month.isAfter(_firstMonth) ? () => _go(-1) : null, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous month'),
            Expanded(child: Text(_monthTitle.format(_month), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
            IconButton(onPressed: _month.isBefore(_lastMonth) ? () => _go(1) : null, icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next month'),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final w in _weekdays) Expanded(child: Text(w, textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++) _day(context, DateTime.utc(_month.year, _month.month, d)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Row(
            children: [
              _Dot(color: c.good),
              const SizedBox(width: AppSpacing.xs),
              Text('Money in', style: TextStyle(color: c.muted, fontSize: 12)),
              const SizedBox(width: AppSpacing.l),
              _Dot(color: c.ink),
              const SizedBox(width: AppSpacing.xs),
              Text('Money out', style: TextStyle(color: c.muted, fontSize: 12)),
            ],
          ),
        ),
        if (selected != null) ...[
          Row(
            children: [
              Expanded(child: Text(_dayName.format(selected), style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 13))),
              if (picked.length > 1)
                Text('${net > 0 ? '+' : net < 0 ? '−' : ''}${Money.format(net.abs())}',
                    style: TextStyle(color: net > 0 ? c.good : c.muted, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          if (picked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Text('Nothing planned on this day.', style: TextStyle(color: c.muted)),
            ),
          for (final item in picked) widget.rowFor(item),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Text('Nothing planned this month.', style: TextStyle(color: c.muted)),
          ),
      ],
    );
  }

  Widget _day(BuildContext context, DateTime day) {
    final c = context.colors;
    final on = _on(day);
    final isSelected = day == _selected;
    final past = day.isBefore(widget.today);
    final isBuyDay = on.any((i) => i.isGoal);
    final hasIn = on.any((i) => i.signedAmount > 0);
    final hasOut = on.any((i) => i.signedAmount < 0);
    final ink = isSelected ? c.onPrimary : past ? c.muted.withValues(alpha: 0.6) : c.ink;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${Dates.weekday(day)} ${Dates.full(day)}${on.isEmpty ? '' : ', ${on.length} planned'}${isBuyDay ? ', buy day' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.small - 2),
        onTap: () => setState(() => _selected = day),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? c.primary : null,
            borderRadius: BorderRadius.circular(AppRadii.small - 2),
            border: isBuyDay && !isSelected ? Border.all(color: c.keep, width: 1.5) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('${day.day}',
                  style: TextStyle(color: ink, fontWeight: day == widget.today || isSelected ? FontWeight.w800 : FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
              if (hasIn || hasOut)
                Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasIn) _Dot(color: isSelected ? c.onPrimary : c.good),
                      if (hasIn && hasOut) const SizedBox(width: 3),
                      if (hasOut) _Dot(color: isSelected ? c.onPrimary : c.ink),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
