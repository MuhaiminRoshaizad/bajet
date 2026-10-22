import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/dates.dart';
import '../../../core/sharing/file_sharer.dart';
import '../../../core/sharing/widget_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/spring_in.dart';
import '../../coach/domain/coach_settings.dart';
import '../../coach/presentation/coach_avatar.dart';
import '../../coach/presentation/coach_providers.dart';
import '../../insights/domain/insights.dart';
import '../../insights/presentation/insights_providers.dart';
import '../../insights/presentation/period_picker.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../opening/presentation/titanium_card.dart';
import '../../plan/presentation/plan_providers.dart';
import '../data/checkin_pdf.dart';
import '../data/report_pdf.dart';
import '../domain/report.dart';
import '../domain/weekly_checkin.dart';
import 'checkin_card.dart';
import 'report_providers.dart';

enum ReportFormat { text, pdf, csv, image }

/// Shares a report of a week, a month or everything, as text to paste, a
/// PDF to keep or a CSV for a spreadsheet.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.initialRange = (period: InsightsPeriod.week, offset: 0)});

  /// The range Insights was showing, so a past month's report is one tap away.
  final InsightsRange initialRange;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late InsightsRange _range = widget.initialRange;

  /// The current week is reported as the Sunday check-in; past weeks and
  /// longer periods as the general report.
  bool get _thisWeek => _range.period == InsightsPeriod.week && _range.offset == 0;
  ReportFormat _format = ReportFormat.text;
  bool _busy = false;

  String _fileName(Insights i, String extension) {
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    return 'bajet-report-${iso(i.from)}-to-${iso(i.to)}.$extension';
  }

  /// The PDF, CSV or image of [i]: its bytes, file name and type.
  Future<(List<int>, String, String)> _file(Insights i, List<Entry> entries, Map<String, Category> categories) async {
    final accounts = ref.read(reportAccountsProvider(_range))!;
    if (_format == ReportFormat.csv) return (utf8.encode(reportCsv(entries, categories, accounts)), _fileName(i, 'csv'), 'text/csv');
    final checkin = _thisWeek ? ref.read(weeklyCheckinProvider) : null;
    if (checkin != null) {
      final name = 'bajet-check-in-${checkin.today.toIso8601String().substring(0, 10)}';
      // The card is shared as 1080 by 1350 pixels, in the theme on screen.
      if (_format == ReportFormat.image) return (await _draw(CheckinCard(w: checkin), CheckinCard.size, pixelRatio: 3), '$name.png', 'image/png');
      return (await _checkinPdf(checkin, categories), '$name.pdf', 'application/pdf');
    }
    final settings = ref.read(settingsProvider).value!;
    final bytes = await reportPdf(
      i: i,
      entries: entries,
      accounts: accounts,
      categories: categories,
      balance: ref.read(balanceProvider).value ?? 0,
      buffer: settings.buffer,
      goal: ref.read(projectionProvider)?.goals.firstOrNull,
      regular: await rootBundle.load('assets/fonts/Figtree-Regular.ttf'),
      bold: await rootBundle.load('assets/fonts/Figtree-Bold.ttf'),
    );
    return (bytes, _fileName(i, 'pdf'), 'application/pdf');
  }

  /// [child] drawn off screen as a PNG, [size] points across, in the theme
  /// on screen or, with [light], the light one. Material gives its text the
  /// app's styles.
  Future<Uint8List> _draw(Widget child, Size size, {required double pixelRatio, bool light = false}) {
    final drawn = Material(type: MaterialType.transparency, child: child);
    return widgetToPng(context, light ? Theme(data: AppTheme.light(), child: drawn) : drawn, size: size, pixelRatio: pixelRatio);
  }

  /// This week's check-in as a PDF, with the app icon and the coach's face
  /// drawn as they are in the app. Paper is light, and the faces change
  /// with the theme, so they are drawn in the light one.
  Future<Uint8List> _checkinPdf(WeeklyCheckin w, Map<String, Category> categories) async {
    final face = (ref.read(coachSettingsProvider).value ?? const CoachSettings()).face;
    final mood = switch (w.verdict) {
      WeekVerdict.onTrack => CoachMood.happy,
      WeekVerdict.short => CoachMood.concerned,
      WeekVerdict.inProgress || WeekVerdict.baseline => CoachMood.idle,
    };
    final icon = await _draw(const AppIconTile(size: 30), const Size.square(30), pixelRatio: 6, light: true);
    final coach = await _draw(CoachAvatar(face: face, mood: mood, size: 46, animate: false, idle: false), const Size.square(46), pixelRatio: 6, light: true);
    final doc = checkinDocument(
      w: w,
      categories: categories,
      icon: icon,
      coach: coach,
      coachName: face.label,
      generatedAt: ref.read(clockProvider)(),
      regular: await rootBundle.load('assets/fonts/Figtree-Regular.ttf'),
      bold: await rootBundle.load('assets/fonts/Figtree-Bold.ttf'),
    );
    return doc.save();
  }

  Future<void> _busyWhile(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(Insights i, String text, List<Entry> entries, Map<String, Category> categories) => _busyWhile(() async {
        final sharer = ref.read(fileSharerProvider);
        if (_format == ReportFormat.text) return sharer.shareText(text, subject: _thisWeek ? 'bajet weekly check-in' : 'bajet report');
        final (bytes, name, type) = await _file(i, entries, categories);
        await sharer.shareFile(bytes, name, type);
      });

  Future<void> _save(Insights i, List<Entry> entries, Map<String, Category> categories) => _busyWhile(() async {
        final messenger = ScaffoldMessenger.of(context);
        final (bytes, name, type) = await _file(i, entries, categories);
        try {
          if (!await ref.read(fileSharerProvider).saveFile(bytes, name, type)) return;
          showBar(messenger, 'Saved $name');
        } on PlatformException {
          showBar(messenger, 'Could not save the file. Share it instead.');
        }
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = ref.watch(insightsForProvider(_range));
    final settings = ref.watch(settingsProvider).value;
    final balance = ref.watch(balanceProvider).value;
    final all = ref.watch(allEntriesProvider).value;
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};
    final accounts = ref.watch(reportAccountsProvider(_range));
    final checkin = _thisWeek ? ref.watch(weeklyCheckinProvider) : null;
    final ready = i != null && settings != null && balance != null && all != null && accounts != null && (checkin != null || !_thisWeek);
    final text = !ready
        ? ''
        : checkin != null
            ? weeklyCheckinText(checkin)
            : reportText(
                i: i,
                accounts: accounts,
                balance: balance,
                weeklyCap: settings.weeklyCap,
                buffer: settings.buffer,
                categories: categories,
                goal: ref.watch(projectionProvider)?.goals.firstOrNull,
              );
    final entries = ready ? entriesIn(i, all) : const <Entry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Share a report')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          PeriodPicker(
            range: _range,
            onChanged: (r) => setState(() {
              _range = r;
              // Only this week has a card to share.
              if (!_thisWeek && _format == ReportFormat.image) _format = ReportFormat.text;
            }),
          ),
          if (ready)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.xs, 0),
              child: Text('${Dates.full(i.from)} to ${Dates.full(i.to)}', style: TextStyle(color: c.muted)),
            ),
          const SizedBox(height: AppSpacing.l),
          // Few options, one choice: radio buttons rather than a dropdown.
          RadioGroup<ReportFormat>(
            groupValue: _format,
            onChanged: (f) => setState(() => _format = f!),
            child: CardGroup(
              children: [
                const RadioListTile(value: ReportFormat.text, title: Text('Text'), subtitle: Text('To paste into a chat or a note')),
                RadioListTile(
                  value: ReportFormat.pdf,
                  title: const Text('PDF'),
                  subtitle: Text(_thisWeek ? 'The check-in on one page, then every entry, to keep or print' : 'A summary, then every entry, to keep or print'),
                ),
                const RadioListTile(value: ReportFormat.csv, title: Text('CSV'), subtitle: Text('Every entry, to open in a spreadsheet')),
                if (_thisWeek) const RadioListTile(value: ReportFormat.image, title: Text('Image'), subtitle: Text("A card of the week to post or send, in the app's colours")),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (ready && _format == ReportFormat.image && checkin != null)
            // The card itself, shrunk to fit; it springs in when picked.
            SpringIn(
              animate: true,
              alignment: Alignment.topCenter,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: FittedBox(child: CheckinCard(w: checkin)),
                  ),
                ),
              ),
            )
          else if (ready && _format == ReportFormat.text)
            SoftWell(
              radius: AppRadii.card,
              child: SelectableText(text, style: const TextStyle(fontSize: 13, height: 1.5, fontFeatures: [FontFeature.tabularFigures()])),
            )
          else if (ready)
            SoftWell(
              radius: AppRadii.card,
              child: Text(
                '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} from ${Dates.full(i.from)} to ${Dates.full(i.to)}.',
                style: TextStyle(color: c.ink),
              ),
            ),
        ],
      ),
      // The action stays in view however long the preview runs.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
          child: Row(
            children: [
              if (_format == ReportFormat.text) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !ready
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              showBar(ScaffoldMessenger.of(context), 'Report copied');
                            }
                          },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
              ] else if (ref.watch(fileSharerProvider).canSave) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !ready || _busy ? null : () => _save(i, entries, categories),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: !ready || _busy ? null : () => _share(i, text, entries, categories),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(switch (_format) {
                    ReportFormat.text => 'Share',
                    ReportFormat.pdf => 'Share PDF',
                    ReportFormat.csv => 'Share CSV',
                    ReportFormat.image => 'Share image',
                  }),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
