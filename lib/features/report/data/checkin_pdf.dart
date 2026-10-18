import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';
import '../domain/weekly_checkin.dart';

/// The weekly check-in as a printable A4 report: the summary first, then
/// every entry of the week, which runs on to further pages with its title
/// and column names repeated when it is long. A block of the summary, such
/// as the verdict or the next seven days, is never split across two pages,
/// and nor is an entry's row. Printed on paper, so it always uses the light
/// palette. [icon] and [coach] are PNGs of the app icon and the coach's
/// face; [regular] and [bold] the app's own Figtree files. Its pages are
/// laid out once it returns; `save` writes the file.
pw.Document checkinDocument({
  required WeeklyCheckin w,
  required Map<String, Category> categories,
  required Uint8List icon,
  required Uint8List coach,
  required String coachName,
  required DateTime generatedAt,
  required ByteData regular,
  required ByteData bold,
}) {
  const c = AppColors.light;
  PdfColor colour(Color from) => PdfColor.fromInt(from.toARGB32());
  final ink = colour(c.ink);
  final muted = colour(c.muted);
  final line = colour(c.line);
  final (bandFill, bandInk, verdict) = switch (w.verdict) {
    WeekVerdict.onTrack => (colour(c.goodSurface), colour(c.good), 'ON TRACK'),
    WeekVerdict.short => (colour(c.badSurface), colour(c.bad), 'SHORT'),
    WeekVerdict.baseline => (colour(c.primarySoft), colour(c.primary), 'BASELINE SET'),
  };
  PdfColor tint(String key) => colour(c.tintInk(Tint.values.asNameMap()[categories[key]?.tint] ?? Tint.neutral));
  final range = '${Dates.dayShort(w.monday)} – ${Dates.dayFull(w.sunday)}';

  pw.TextStyle text({double size = 9, PdfColor? colour, bool strong = false}) =>
      pw.TextStyle(fontSize: size, color: colour ?? ink, fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal);
  pw.Widget title(String label) => pw.Text(label, style: text(size: 11, strong: true));
  // Each block stays whole on one page; only tables break, between rows.
  pw.Widget block(List<pw.Widget> children, {double top = 14}) => pw.Padding(
        padding: pw.EdgeInsets.only(top: top),
        child: pw.Inseparable(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: children)),
      );
  pw.Widget pill(String label, PdfColor tone, {bool outline = false}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: pw.BoxDecoration(
          color: outline ? null : tone,
          border: outline ? pw.Border.all(color: tone, width: 1) : null,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Text(label, style: text(colour: outline ? tone : PdfColors.white, strong: true)),
      );
  pw.Widget figure(String label, String value, String note) => pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: text(size: 8, colour: muted)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: text(size: 15, strong: true)),
          pw.Text(note, style: text(size: 8, colour: muted)),
        ]),
      );

  final goal = w.goal;
  final safe = w.goalSafe;
  final under = w.plan - w.spent;

  final heading = block(top: 0, [
    pw.Row(children: [
      pw.Image(pw.MemoryImage(icon), width: 30, height: 30),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('bajet · Weekly check-in', style: text(size: 18, strong: true)),
          pw.Text(
            [range, if (w.dataDays < 7) '${w.first ? 'First check-in · ' : ''}${w.dataDays} ${w.dataDays == 1 ? 'day' : 'days'} of data'].join('  ·  '),
            style: text(colour: muted),
          ),
        ]),
      ),
    ]),
    pw.SizedBox(height: 14),
    // The verdict, with the coach's face beside it.
    pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: pw.BoxDecoration(color: bandFill, borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Row(children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(children: [
              pill(verdict, bandInk),
              if (safe != null) ...[pw.SizedBox(width: 6), pill('Goal ${safe ? 'SAFE' : 'SHORT'}', colour(safe ? c.good : c.bad), outline: true)],
            ]),
            pw.SizedBox(height: 6),
            pw.Text(
              switch (w.target) {
                null => 'Balance ${Money.format(w.balance)} · target for ${Dates.dayShort(w.nextCheck)} set at this check-in',
                final t => 'Balance ${Money.format(w.balance)} vs target ${Money.format(t)} (${signedMoney(w.difference!)})',
              },
              style: text(size: 10, colour: bandInk, strong: true),
            ),
            pw.Text(
              [
                'Bank match: ${switch (w.matched) { true => 'yes', false => 'no', null => 'not checked yet' }}',
                if (w.startingAdjustment > 0) 'starting adjustment ${Money.format(w.startingAdjustment)}' else 'untracked ${Money.format(w.untracked)}',
              ].join(' · '),
              style: text(size: 8.5, colour: bandInk),
            ),
          ]),
        ),
        pw.Column(children: [
          pw.Image(pw.MemoryImage(coach), width: 46, height: 46),
          pw.Text(coachName, style: text(size: 7, colour: bandInk)),
        ]),
      ]),
    ),
  ]);

  final week = block([
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      figure(w.from == w.monday ? 'Spent of allowance' : 'Spent of plan', '${Money.format(w.spent)} / ${Money.format(w.plan)}',
          '${Money.format(under.abs())} ${under >= 0 ? 'under' : 'over'}'),
      if (goal != null) ...[
        figure('Left after buying', Money.format(goal.leftAfterBuying), w.change == null ? 'first figure' : '${signedMoney(w.change!)} since last check-in'),
        figure('Days to buy day', '${w.daysToGo}', '${goal.goal.name} · ${Dates.dayFull(goal.goal.targetDate)}'),
      ],
    ]),
    pw.SizedBox(height: 12),
    pw.Row(children: [
      for (final (n, d) in w.days.indexed) ...[
        if (n > 0) pw.SizedBox(width: 4),
        pw.Expanded(child: _day(d, text: text, muted: muted, line: line, well: colour(c.well), over: colour(c.badSurface), fast: colour(c.keep))),
      ],
    ]),
  ]);

  final spending = block([
    title('Where it went'),
    pw.SizedBox(height: 6),
    pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Row(children: [
        for (final cat in w.categories) pw.Expanded(flex: cat.amount, child: pw.Container(height: 8, color: tint(cat.key))),
      ]),
    ),
    pw.SizedBox(height: 4),
    pw.Wrap(spacing: 12, runSpacing: 2, children: [
      for (final cat in w.categories)
        pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: tint(cat.key), shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 4),
          pw.Text('${cat.label} ${Money.format(cat.amount)}', style: text(size: 8.5)),
        ]),
    ]),
  ]);

  // A week has at most two rules a day, so the table stays one block.
  final rules = block([
    title('Rules'),
    pw.SizedBox(height: 4),
    _table(
      [
        for (final r in w.rules)
          [
            pw.Text(r.name, style: text()),
            pw.Text(r.how, style: text(colour: muted)),
            pw.Text(r.kept ? 'Kept' : 'Missed', style: text(colour: colour(r.kept ? c.good : c.bad), strong: true)),
          ],
      ],
      line: line,
      right: {2},
    ),
  ]);

  final next = block([
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: line), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        title('Next 7 days'),
        pw.SizedBox(height: 4),
        if (w.next.isEmpty) pw.Text('Nothing due', style: text(colour: muted)),
        for (final item in w.next)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(children: [
              pw.SizedBox(width: 62, child: pw.Text(Dates.dayShort(item.date), style: text(colour: muted))),
              pw.Expanded(child: pw.Text('${item.name}${item.counted ? '' : ' (unconfirmed)'}', style: text())),
              pw.Text(signedMoney(item.signedAmount), style: text(strong: true)),
            ]),
          ),
        pw.SizedBox(height: 4),
        pw.Text('Next check-in ${Dates.dayShort(w.nextCheck)}: stay above ${Money.format(w.nextTarget)}', style: text(strong: true)),
        if (w.withUnconfirmed != null) pw.Text('With unconfirmed income, ${Money.format(w.withUnconfirmed!)} left after buying', style: text(size: 8, colour: muted)),
      ]),
    ),
  ]);

  final flags = block([
    title('Flags'),
    pw.SizedBox(height: 4),
    for (final f in w.flags) pw.Bullet(text: f, style: text(colour: colour(c.bad)), bulletColor: colour(c.bad)),
  ]);

  var spent = 0;
  final entries = w.entries.isEmpty
      ? block([title('Entries'), pw.SizedBox(height: 4), pw.Text('Nothing logged this week.', style: text(colour: muted))])
      : pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14),
          child: _table(
            [
              for (final e in w.entries)
                [
                  pw.Text(Dates.dayShort(e.day), style: text(colour: muted)),
                  pw.Text([categories[e.categoryKey]?.label ?? e.categoryKey, e.label, e.note].whereType<String>().join(' · '), style: text()),
                  pw.Text(signedMoney(e.signedAmount), style: text()),
                  pw.Text(Money.format(spent += e.isIncome ? 0 : e.amount), style: text(colour: muted)),
                ],
            ],
            // The title and column names come back at the top of every page
            // the entries run on to.
            headers: [
              [title('Entries'), pw.SizedBox(), pw.SizedBox(), pw.SizedBox()],
              [for (final h in ['Date', 'Category · note', 'Amount', 'Spent so far']) pw.Text(h, style: text(size: 8, colour: muted, strong: true))],
            ],
            line: line,
            right: {2, 3},
            widths: const {0: pw.FixedColumnWidth(56), 1: pw.FlexColumnWidth(), 2: pw.FixedColumnWidth(70), 3: pw.FixedColumnWidth(70)},
          ),
        );

  final doc = pw.Document(
    title: 'bajet weekly check-in $range',
    theme: pw.ThemeData.withFont(base: pw.Font.ttf(regular), bold: pw.Font.ttf(bold)),
  );
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
    maxPages: 50,
    header: (context) => context.pageNumber == 1
        ? pw.SizedBox()
        : pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('bajet · Weekly check-in · $range (continued)', style: text(size: 8, colour: muted)),
          ),
    footer: (context) => pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: line, width: .5))),
      child: pw.Row(children: [
        pw.Text('bajet · local data', style: text(size: 7.5, colour: muted)),
        pw.Spacer(),
        pw.Text(
          'Generated ${Dates.full(generatedAt)} ${DateFormat('HH:mm').format(generatedAt)} · Page ${context.pageNumber} of ${context.pagesCount}',
          style: text(size: 7.5, colour: muted),
        ),
      ]),
    ),
    build: (context) => [
      heading,
      week,
      if (w.categories.isNotEmpty) spending,
      if (w.rules.isNotEmpty) rules,
      next,
      if (w.flags.isNotEmpty) flags,
      // Starts a new page rather than leave the entries' title and column
      // names at the foot of one with too few rows under them.
      pw.NewPage(freeSpace: 110),
      entries,
    ],
  ));
  return doc;
}

/// One day of the week: its spending, its kind and, on a fasting day, a
/// mark.
pw.Widget _day(
  CheckinDay d, {
  required pw.TextStyle Function({double size, PdfColor? colour, bool strong}) text,
  required PdfColor muted,
  required PdfColor line,
  required PdfColor well,
  required PdfColor over,
  required PdfColor fast,
}) {
  final finished = d.state == CheckinDayState.finished;
  final kind = switch (d.state) {
    CheckinDayState.noData => 'No data',
    CheckinDayState.today => 'Today',
    CheckinDayState.ahead => 'Later',
    CheckinDayState.finished when d.rule.isFastingDay => 'Fasting',
    CheckinDayState.finished => switch (d.rule.type) { DayType.zero => 'No spending', DayType.flex => 'Flexible', DayType.spend => 'Spending' },
  };
  return pw.Container(
    height: 58,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
    decoration: pw.BoxDecoration(
      color: finished ? (d.over ? over : well) : null,
      border: finished ? null : pw.Border.all(color: line, width: .8),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(children: [
      pw.Text('${Dates.weekday(d.date)} ${Dates.short(d.date)}', style: text(size: 7.5, colour: muted)),
      pw.SizedBox(height: 3),
      pw.Text(finished || d.state == CheckinDayState.today ? Money.format(d.spent) : '–', style: text(size: 9.5, strong: true)),
      pw.Spacer(),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        if (d.rule.isFastingDay && d.state != CheckinDayState.noData) ...[
          pw.Container(width: 5, height: 5, decoration: pw.BoxDecoration(color: fast, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 2),
        ],
        pw.Text(kind, style: text(size: 7, colour: muted)),
      ]),
    ]),
  );
}

/// Rows of cells divided by hairlines, with the [right] columns aligned
/// right since they hold money. The [headers] rows repeat on every page.
pw.Widget _table(
  List<List<pw.Widget>> rows, {
  List<List<pw.Widget>> headers = const [],
  required PdfColor line,
  Set<int> right = const {},
  Map<int, pw.TableColumnWidth> widths = const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1)},
}) {
  pw.TableRow row(List<pw.Widget> cells, {bool repeat = false}) => pw.TableRow(
        repeat: repeat,
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          for (final (n, cell) in cells.indexed)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: right.contains(n) ? pw.Align(alignment: pw.Alignment.centerRight, child: cell) : cell,
            ),
        ],
      );
  return pw.Table(
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: line, width: .5)),
    columnWidths: widths,
    children: [for (final h in headers) row(h, repeat: true), for (final r in rows) row(r)],
  );
}
