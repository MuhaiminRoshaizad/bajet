import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../insights/domain/insights.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/projection.dart';
import '../domain/report.dart';

/// A printable report of [i]: a summary on the first page, then every entry
/// in the period. Printed on paper, so it always uses the light palette.
/// [regular] and [bold] are the app's own Figtree files, so RM and every
/// label render exactly as in the app.
Future<Uint8List> reportPdf({
  required Insights i,
  required List<Entry> entries,
  required List<AccountLine> accounts,
  required Map<String, Category> categories,
  required int balance,
  required int buffer,
  required GoalOutcome? goal,
  required ByteData regular,
  required ByteData bold,
}) {
  const c = AppColors.light;
  final ink = PdfColor.fromInt(c.ink.toARGB32());
  final muted = PdfColor.fromInt(c.muted.toARGB32());
  final primary = PdfColor.fromInt(c.primary.toARGB32());
  final keep = PdfColor.fromInt(c.keep.toARGB32());
  final bad = PdfColor.fromInt(c.bad.toARGB32());
  final line = PdfColor.fromInt(c.line.toARGB32());

  final doc = pw.Document(
    title: 'bajet report ${Dates.full(i.from)} to ${Dates.full(i.to)}',
    theme: pw.ThemeData.withFont(base: pw.Font.ttf(regular), bold: pw.Font.ttf(bold)),
  );
  pw.Widget figure(String label, String value, PdfColor tone) => pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(color: muted, fontSize: 9)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(color: tone, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink)),
      );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    maxPages: 200,
    footer: (context) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(color: muted, fontSize: 8)),
    ),
    build: (context) => [
      pw.Text('bajet report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: ink)),
      pw.Text('${Dates.full(i.from)} to ${Dates.full(i.to)} · balance today ${Money.format(balance)}', style: pw.TextStyle(color: muted, fontSize: 10)),
      pw.SizedBox(height: 14),
      pw.Row(children: [
        figure('Money in', Money.format(i.moneyIn), primary),
        figure('Money out', Money.format(i.moneyOut), ink),
        // A week rarely holds a payday, so it shows what went on wants
        // rather than in against out.
        if (i.period == InsightsPeriod.week)
          figure('Wants', Money.format(i.outOf(OutPart.wants)), ink)
        else
          figure(i.kept >= 0 ? 'Kept' : 'Spent more than came in', Money.format(i.kept.abs()), i.kept >= 0 ? keep : bad),
        figure('Untracked', Money.format(i.untrackedOut), i.untrackedOut > 0 ? bad : ink),
      ]),
      if (accounts.length > 1) ...[
        heading('By account'),
        _table(
          [
            ['Account', 'In', 'Out', 'Now'],
            for (final a in accounts) [a.name, Money.format(a.moneyIn), Money.format(a.moneyOut), Money.format(a.balance)],
          ],
          line: line,
          ink: ink,
          header: true,
          amounts: 3,
        ),
      ],
      if (i.moneyOut > 0) ...[
        heading('Money out by kind'),
        _table(
          [
            for (final (part, name) in outPartNames)
              if (i.outOf(part) > 0) [name, Money.format(i.outOf(part))],
          ],
          line: line,
          ink: ink,
        ),
      ],
      if (i.outByCategory.isNotEmpty) ...[
        heading('Money out by category'),
        _table([for (final (key, amount) in i.outByCategory) [categoryName(categories, key), Money.format(amount)]], line: line, ink: ink),
      ],
      heading('Habits'),
      pw.Bullet(text: '${i.daysWithinPlan} of ${i.daysSoFar} finished days within plan, ${i.zeroSpendDays} with no flexible spending', style: pw.TextStyle(color: ink, fontSize: 10)),
      if (i.fullWeeks > 0) pw.Bullet(text: '${i.weeksUnderAllowance} of ${i.fullWeeks} whole weeks under the allowance', style: pw.TextStyle(color: ink, fontSize: 10)),
      if (i.frequent != null)
        pw.Bullet(text: 'Usual ${i.frequent!.label.toLowerCase()}: ${Money.format(i.frequent!.average)} over ${i.frequent!.count} times', style: pw.TextStyle(color: ink, fontSize: 10)),
      if (goal != null) ...[
        heading('Goal'),
        pw.Text(
          '${goal.goal.name}, ${Money.format(goal.goal.price)} on ${Dates.full(goal.goal.targetDate)}. Projected left after buying: '
          '${Money.format(goal.leftAfterBuying)}, ${goal.onTrack ? 'on track' : 'short'} against a ${Money.format(buffer)} buffer.',
          style: pw.TextStyle(color: goal.onTrack ? keep : bad, fontSize: 10),
        ),
      ],
      heading('Every entry'),
      if (entries.isEmpty)
        pw.Text('Nothing logged in this period.', style: pw.TextStyle(color: muted, fontSize: 10))
      else
        _table(
          [
            ['Date', if (accounts.length > 1) 'Account', 'Category', 'Label and note', 'Amount'],
            for (final e in entries)
              [
                Dates.full(e.day),
                if (accounts.length > 1) accountOf(accounts, e),
                categories[e.categoryKey]?.label ?? e.categoryKey,
                [e.label, e.note].whereType<String>().join(' · '),
                '${e.isIncome ? '+' : '−'}${Money.format(e.amount)}',
              ],
          ],
          line: line,
          ink: ink,
          header: true,
        ),
    ],
  ));
  return doc.save();
}

/// Rows of text with the last [amounts] columns right-aligned, since they
/// hold money.
pw.Widget _table(List<List<String>> rows, {required PdfColor line, required PdfColor ink, bool header = false, int amounts = 1}) {
  final right = {for (var n = rows.first.length - amounts; n < rows.first.length; n++) n: pw.Alignment.centerRight};
  return pw.TableHelper.fromTextArray(
    data: rows,
    headerCount: header ? 1 : 0,
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: line, width: 0.5)),
    cellStyle: pw.TextStyle(color: ink, fontSize: 9),
    headerStyle: pw.TextStyle(color: ink, fontSize: 9, fontWeight: pw.FontWeight.bold),
    cellAlignments: right,
    headerAlignment: pw.Alignment.centerLeft,
    headerAlignments: right,
    cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
  );
}
