import '../../../core/widgets/app_sheet.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/presentation/account_choice.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../../plan/domain/plan_models.dart' show PlannedEvent, RecurringItem, calendarDay;
import '../../plan/presentation/plan_providers.dart';
import '../domain/ledger_models.dart';
import 'category_visuals.dart';
import 'detail_tile.dart';
import 'ledger_providers.dart';
import 'receipt_widgets.dart';
import 'spend_kind_choice.dart';

/// What to fill the logger with when it opens from somewhere that already
/// knows part of the entry. Nothing is saved until Log is pressed.
class LogPrefill {
  const LogPrefill({this.isIncome = false, this.amount, this.categoryKey, this.label, this.accountId, this.billId});

  final bool isIncome;
  final int? amount;
  final String? categoryKey;
  final String? label;

  /// The account it belongs to, such as the one a check-in found short.
  final int? accountId;

  /// The bill or income it is for, already picked, as Paid on Today does.
  final int? billId;
}

/// Opens the logger, with [prefill] filled in, or with [editing] the same
/// form filled in with an existing entry. Saving shows a snackbar with undo
/// on [messengerContext]'s scaffold, which outlives the sheet.
Future<void> showLogSheet(BuildContext messengerContext, {Entry? editing, LogPrefill? prefill}) => showAppSheet<void>(
      context: messengerContext,
      // Over the bottom bar wherever it is opened from; from inside a tab it
      // would otherwise sit under the bar, its Log button beneath it.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _LogSheet(messenger: ScaffoldMessenger.of(messengerContext), editing: editing, prefill: prefill),
    );

class _LogSheet extends ConsumerStatefulWidget {
  const _LogSheet({required this.messenger, this.editing, this.prefill});

  final ScaffoldMessengerState messenger;
  final Entry? editing;
  final LogPrefill? prefill;

  @override
  ConsumerState<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<_LogSheet> {
  static const _amountFormatter = RinggitCentsFormatter(maxSen: 9999999, prefix: 'RM'); // RM99,999.99

  bool _isIncome = false;
  final _amountText = TextEditingController();
  String? _categoryKey;
  String? _label;
  int? _favouriteId;
  String? _receipt;

  /// The planned event this spend is for, if any; its budget plans for it,
  /// so it stays out of the weekly allowance.
  EventLink? _event;

  /// The bill or income this entry pays or receives, if any.
  int? _billId;

  /// A want or a need; it starts as the category's kind whenever a category
  /// is picked, and the user changes it for this spend alone.
  SpendKind _spendKind = SpendKind.want;

  /// Where the money came from or went to; null until known means the
  /// first account.
  int? _accountId;
  final _note = TextEditingController();
  late DateTime _day = ref.read(todayProvider);
  bool _saving = false;

  int get _amount => RinggitCentsFormatter.parse(_amountText.text);

  void _setAmount(int sen) => _amountText.text = sen == 0 ? '' : '${_amountFormatter.prefix}${RinggitCentsFormatter.format(sen)}';

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _isIncome = e.isIncome;
      _setAmount(e.amount);
      _categoryKey = e.categoryKey;
      _label = e.label;
      _note.text = e.note ?? '';
      _day = e.day;
      _receipt = e.receipt;
      _event = e.event;
      _accountId = e.accountId;
      _billId = e.billId;
      _spendKind = e.spendKind;
    } else {
      // Most money goes where the last of it went.
      _accountId = ref.read(recentEntriesProvider).value?.firstOrNull?.accountId;
    }
    final p = widget.prefill;
    if (p != null) {
      _isIncome = p.isIncome;
      _setAmount(p.amount ?? 0);
      _categoryKey = p.categoryKey;
      _label = p.label;
      _accountId = p.accountId ?? _accountId;
      _billId = p.billId;
      if (p.categoryKey case final key?) _spendKind = _startingKind(key);
    }
  }

  SpendKind _startingKind(String categoryKey) =>
      ref.read(categoriesProvider).value?.where((c) => c.key == categoryKey).firstOrNull?.spendKind ?? SpendKind.want;

  @override
  void dispose() {
    _note.dispose();
    _amountText.dispose();
    super.dispose();
  }

  void _useFavourite(Favourite f) => setState(() {
        _isIncome = false;
        _favouriteId = f.id;
        _categoryKey = f.categoryKey;
        _spendKind = _startingKind(f.categoryKey);
        _label = f.label;
        _setAmount(f.amount);
      });

  /// Picks [item] as what this entry is for, or unpicks it. A sheet with no
  /// amount yet takes the planned one, which can then be typed over.
  void _pickBill(RecurringItem item) => setState(() {
        if (_billId == item.id) {
          _billId = null;
          return;
        }
        _billId = item.id;
        _event = null;
        _favouriteId = null;
        _categoryKey = item.categoryKey;
        _spendKind = _startingKind(item.categoryKey);
        _label = item.name;
        _accountId = item.accountId ?? _accountId;
        if (_amount == 0) _setAmount(item.amount);
      });

  void _pickEvent(PlannedEvent e) => setState(() {
        final link = EventLink(e.id, e.date);
        _event = _event == link ? null : link;
        _billId = null;
        if (_event == null) return;
        _categoryKey ??= e.categoryKey;
        // Income for an event is named after it, as a bill's payment is.
        if (e.isIncome) _label ??= e.name;
      });

  /// Only day-to-day spending is a want or a need: income, fixed
  /// categories, bills and planned events are planned already.
  bool get _asksKind =>
      !_isIncome &&
      _billId == null &&
      _event == null &&
      !(ref.read(categoriesProvider).value?.where((c) => c.key == _categoryKey).firstOrNull?.isFixed ?? false);

  void _pickCategory(String key) => setState(() {
        _categoryKey = key;
        _spendKind = _startingKind(key);
        _favouriteId = null;
        _label = null;
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    final draft = EntryDraft(
      day: _day,
      isIncome: _isIncome,
      amount: _amount,
      categoryKey: _categoryKey!,
      label: _label,
      note: _note.text,
      receipt: _receipt,
      event: _event,
      accountId: _accountId,
      billId: _billId,
      spendKind: _spendKind,
    );
    final repo = ref.read(ledgerRepositoryProvider);
    final before = widget.editing;
    final String message;
    final VoidCallback undo;
    if (before == null) {
      final id = await repo.add(draft);
      // What it was for says what happened to it: a bill paid, income received.
      final settled = _billId != null || (_isIncome && _event != null);
      final verb = settled ? (_isIncome ? 'Received' : 'Paid') : (_isIncome ? 'Added' : 'Logged');
      final asNeed = _asksKind && _spendKind == SpendKind.need ? ' as a need' : '';
      message = '$verb ${_label ?? _categoryLabel(_categoryKey!)} ${Money.format(draft.amount)}$asNeed';
      undo = () => repo.delete(id);
    } else {
      await repo.update(Entry(
        id: before.id,
        day: draft.day,
        isIncome: draft.isIncome,
        amount: draft.amount,
        categoryKey: draft.categoryKey,
        label: draft.label,
        note: draft.note,
        receipt: draft.receipt,
        event: draft.event,
        accountId: draft.accountId,
        billId: before.billId,
        spendKind: draft.spendKind,
      ));
      message = 'Saved changes';
      undo = () => repo.update(before);
    }
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    Navigator.of(context).pop();
    showBar(widget.messenger, message, undo: undo);
  }

  /// Removes the entry being edited, after asking, with Undo on the page.
  Future<void> _delete() async {
    final entry = widget.editing!;
    final name = entry.label ?? _categoryLabel(entry.categoryKey);
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this entry?',
      message: '$name ${Money.format(entry.amount)} on ${Dates.full(entry.day)}. '
          'Your balance will change by ${entry.isIncome ? '−' : '+'}${Money.format(entry.amount)}.',
    );
    if (!confirmed || !mounted) return;
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.delete(entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showBar(widget.messenger, 'Deleted $name', undo: () => repo.restore(entry));
  }

  void _manageFavourites() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.favourites);
  }

  String _categoryLabel(String key) =>
      ref.read(categoriesProvider).value?.firstWhere((c) => c.key == key).label ?? key;

  /// The opening date when [day] falls before it, for the note under Day.
  DateTime? _beforeOpening(DateTime day) {
    final opening = ref.watch(settingsProvider).value?.openingDate;
    return opening != null && day.isBefore(opening) ? opening : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((cat) => cat.isIncome == _isIncome && !cat.isAutomatic)];
    final favourites = ref.watch(favouritesProvider).value ?? const [];
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final ready = _amount > 0 && _categoryKey != null && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The toggle sits in the middle; a box as wide as the close
          // button on the left keeps it truly centred.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Spacer(),
                _KindToggle(
                  isIncome: _isIncome,
                  onChanged: (v) => setState(() {
                    _isIncome = v;
                    _categoryKey = null;
                    _favouriteId = null;
                    _label = null;
                    _event = null;
                    _billId = null;
                  }),
                ),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded), tooltip: 'Close'),
              ],
            ),
          ),
          // The amount stays in view above the choices, which scroll; the
          // phone's number pad waits until the amount is tapped, so the
          // favourites and categories can be seen first.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s),
                // The amount reads out of a display set into the sheet, typed
                // on the number pad and filled from the right like a till.
                SoftWell(
                  radius: AppRadii.card,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: TextField(
                    autofillHints: null,
                    key: const ValueKey('amount'),
                    controller: _amountText,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    inputFormatters: const [_amountFormatter],
                    onChanged: (_) => setState(() => _favouriteId = null),
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1, color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
                    decoration: InputDecoration(
                      hintText: 'RM0.00',
                      hintStyle: TextStyle(color: c.muted),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      semanticCounterText: '',
                      labelText: null,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Center(
                  child: _event == null || _isIncome
                      ? _PlanHint(amount: _amount, isIncome: _isIncome, forBill: _billId != null, categoryKey: _categoryKey, day: _day, editing: widget.editing)
                      : _EventHint(link: _event!, amount: _amount, editing: widget.editing),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isIncome && favourites.isEmpty && widget.editing == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _manageFavourites,
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Set up favourites for things you buy often'),
                      ),
                    ),
                  if (!_isIncome && favourites.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        _SectionLabel('Favourites'),
                        const Spacer(),
                        TextButton(onPressed: _manageFavourites, style: TextButton.styleFrom(minimumSize: const Size(48, 40)), child: const Text('Edit')),
                      ],
                    ),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        // Room for the chips' shadows, which a list clips.
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.s - 2),
                        itemCount: favourites.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
                        itemBuilder: (_, i) {
                          final f = favourites[i];
                          final cat = categories.where((x) => x.key == f.categoryKey).firstOrNull;
                          return _FavouriteChip(
                            favourite: f,
                            tint: categoryTint(cat),
                            selected: _favouriteId == f.id,
                            onTap: () => _useFavourite(f),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  _SectionLabel('Category'),
                  const SizedBox(height: AppSpacing.s),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Room around each tile for its shadow.
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    mainAxisSpacing: AppSpacing.m,
                    crossAxisSpacing: AppSpacing.m,
                    // Taller as the label's text grows, read at its own size
                    // since large text is not scaled as much, so a small phone
                    // with large text still fits the name under the icon.
                    childAspectRatio: 1.1 / math.max(1.0, MediaQuery.textScalerOf(context).scale(12) / 12),
                    children: [
                      for (final cat in categories)
                        _CategoryTile(category: cat, selected: _categoryKey == cat.key, onTap: () => _pickCategory(cat.key)),
                    ],
                  ),
                  AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.enter,
                    curve: Curves.easeOutBack,
                    alignment: Alignment.topCenter,
                    child: _asksKind
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.m),
                            child: SpendKindChoice(kind: _spendKind, onSelect: (k) => setState(() => _spendKind = k)),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  // An entry being edited keeps the bill it paid; picking
                  // another would move a bill's month by surprise.
                  _DueChoice(isIncome: _isIncome, day: _day, billId: _billId, event: _event, bills: widget.editing == null, onBill: _pickBill, onEvent: _pickEvent),
                  // With one account there is nothing to choose.
                  if (accounts.length > 1) ...[
                    const SizedBox(height: AppSpacing.m),
                    AccountChoice(
                      label: _isIncome ? 'Paid into' : 'Paid from',
                      accounts: accounts,
                      selected: accounts.any((a) => a.id == _accountId) ? _accountId : accounts.first.id,
                      onSelect: (id) => setState(() => _accountId = id),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  // Full width, so the label is never cut short.
                  TextField(
                    autofillHints: null,
                    controller: _note,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Lunch with team', counterText: ''),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // The day and the receipt as a matched pair; padded for
                  // the tiles' shadows.
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(child: _DayTile(day: _day, onChanged: (d) => setState(() => _day = d))),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(child: ReceiptTile(receipt: _receipt, onChanged: (r) => setState(() => _receipt = r))),
                      ],
                    ),
                  ),
                  if (_beforeOpening(_day) case final opening?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.xs, AppSpacing.s, 0),
                      child: Text(
                        "This is before you set up bajet on ${Dates.full(opening)}. It counts in that week and Insights, but not in your balance, which already had it taken off.",
                        key: const ValueKey('before-opening'),
                        style: TextStyle(color: context.colors.muted, fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s),
                  if (widget.editing != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    DeleteButton(label: 'Delete entry', onPressed: _delete),
                    const SizedBox(height: AppSpacing.s),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.s, AppSpacing.xl, AppSpacing.l),
            child: FilledButton(
              onPressed: ready ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control + 4)),
              ),
              child: Text(
                _amount == 0
                    ? 'Type the amount'
                    : _categoryKey == null
                        ? 'Pick a category'
                        : widget.editing != null
                            ? 'Save changes'
                            : '${_isIncome ? 'Add' : 'Log'} ${Money.format(_amount)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What this entry is for, when anything is due near its day: the bills
/// (or, for income, the income) due, and the planned events, as tiles like
/// Favourites, soonest first. Shown only when there is one, so most logs
/// never see it.
class _DueChoice extends ConsumerWidget {
  const _DueChoice({required this.isIncome, required this.day, required this.billId, required this.event, required this.bills, required this.onBill, required this.onEvent});

  /// Two weeks either side: a gift is bought before the day or just after,
  /// and a bill is paid a little early or late.
  static const _near = 14;

  final bool isIncome;
  final DateTime day;
  final int? billId;
  final EventLink? event;

  /// Whether bills and income are offered, not only events.
  final bool bills;
  final ValueChanged<RecurringItem> onBill;
  final ValueChanged<PlannedEvent> onEvent;

  bool _isNear(DateTime d) => calendarDay(d).difference(day).inDays.abs() <= _near;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final items = [
      if (bills)
        ...?ref.watch(recurringProvider).value?.where((r) =>
            r.active && r.isIncome == isIncome && (r.id == billId || _isNear(r.nextDue) || r.nextDue.isBefore(day))),
    ];
    final events = [
      ...?ref.watch(eventsProvider).value?.where((e) => e.isIncome == isIncome && !e.done && (e.id == event?.eventId || _isNear(e.date))),
    ];
    final choices = [
      for (final r in items) (r.nextDue, _Due.bill(r)),
      for (final e in events) (e.date, _Due.event(e)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (choices.isEmpty) return const SizedBox.shrink();
    Tint tintOf(String key) => categoryTint(categories.where((x) => x.key == key).firstOrNull);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(!bills ? 'For an event (optional)' : isIncome ? 'For your income or an event (optional)' : 'For a bill or an event (optional)'),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Room for the tiles' shadows, which a list clips.
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.s - 2),
              itemCount: choices.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
              itemBuilder: (_, i) => switch (choices[i].$2) {
                _DueBill(:final item) => _DueTile(
                    key: ValueKey('due-bill-${item.id}'),
                    categoryKey: item.categoryKey,
                    tint: tintOf(item.categoryKey),
                    name: item.name,
                    detail: '${Money.format(item.amount)} · ${isIncome ? 'expected' : 'due'} ${Dates.short(item.nextDue)}',
                    selected: billId == item.id,
                    onTap: () => onBill(item),
                  ),
                _DueEvent(:final item) => _DueTile(
                    key: ValueKey('due-event-${item.id}'),
                    categoryKey: item.categoryKey,
                    tint: tintOf(item.categoryKey),
                    name: item.name,
                    detail: isIncome ? '${Money.format(item.amount)} planned · ${Dates.short(item.date)}' : '${Money.format(item.outstanding)} left',
                    selected: event?.eventId == item.id,
                    onTap: () => onEvent(item),
                  ),
              },
            ),
          ),
          if (billId != null || event != null)
            Text(
              isIncome ? 'Type what really came in; it counts instead of the planned amount.' : 'Type what was really paid; it counts instead of the planned amount.',
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// One thing a log can be for, in [_DueChoice].
sealed class _Due {
  const _Due();
  const factory _Due.bill(RecurringItem item) = _DueBill;
  const factory _Due.event(PlannedEvent item) = _DueEvent;
}

class _DueBill extends _Due {
  const _DueBill(this.item);
  final RecurringItem item;
}

class _DueEvent extends _Due {
  const _DueEvent(this.item);
  final PlannedEvent item;
}

/// A tile in [_DueChoice], drawn as the Favourites are: the category's
/// bubble, the name, and the planned amount with when it is due.
class _DueTile extends StatelessWidget {
  const _DueTile({super.key, required this.categoryKey, required this.tint, required this.name, required this.detail, required this.selected, required this.onTap});

  final String categoryKey;
  final Tint tint;
  final String name;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftButton(
      selected: selected,
      onTap: onTap,
      semanticLabel: 'For $name, $detail',
      padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.xs, AppSpacing.m, AppSpacing.xs),
      child: Row(
        children: [
          CategoryBubble(categoryKey: categoryKey, tint: tint, size: 34),
          const SizedBox(width: AppSpacing.s),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(detail, style: TextStyle(color: c.muted, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ],
      ),
    );
  }
}

/// In place of the day's plan: what is left of the event's budget after
/// this spend, since the spend comes out of that budget, not the allowance.
class _EventHint extends ConsumerWidget {
  const _EventHint({required this.link, required this.amount, required this.editing});

  final EventLink link;
  final int amount;
  final Entry? editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final event = ref.watch(eventsProvider).value?.where((e) => e.id == link.eventId).firstOrNull;
    if (event == null) return const SizedBox.shrink();
    // An entry being edited is already counted in what the event has spent.
    final already = editing?.event == link ? editing!.amount : 0;
    final left = event.amount - (event.spent - already) - amount;
    final over = left < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(color: over ? c.badSurface : c.keepSurface, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(
        over ? '${Money.format(-left)} over the ${event.name} budget' : '${Money.format(left)} left of the ${event.name} budget',
        style: TextStyle(color: over ? c.bad : c.keep, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Says whether the amount fits the day's planned spend, and by how much it
/// would set the goal back if not. Fixed costs, bills and income get no hint.
class _PlanHint extends ConsumerWidget {
  const _PlanHint({required this.amount, required this.isIncome, required this.forBill, required this.categoryKey, required this.day, required this.editing});

  final int amount;
  final bool isIncome;
  final bool forBill;
  final String? categoryKey;
  final DateTime day;
  final Entry? editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final categories = ref.watch(categoriesProvider).value;
    final rules = ref.watch(rulesProvider).value;
    // Every entry, since the day can be up to a year back. An entry being
    // edited is already logged; leave it out so it is not counted twice,
    // once as logged and once as the amount typed.
    final entries = ref.watch(allEntriesProvider).value?.where((e) => e.id != editing?.id);
    final category = categories?.where((x) => x.key == categoryKey).firstOrNull;
    if (isIncome || forBill || amount == 0 || category == null || category.isFixed || rules == null || entries == null) {
      return const SizedBox(height: 28);
    }
    final fixed = {for (final x in categories!.where((x) => x.isFixed)) x.key};
    final planned = rules.where((r) => r.weekday == day.weekday).firstOrNull?.plannedSpend ?? 0;
    final room = (planned - wantsSpent(entries, fixed, day, day)).clamp(0, planned);
    final over = amount - room;
    final whose = day == ref.read(todayProvider) ? "today's" : "that day's";
    final (bg, fg, text) = over > 0
        ? (c.badSurface, c.bad, '${Money.format(over)} over $whose ${Money.format(planned)} plan')
        : (c.goodSurface, c.good, 'Within $whose plan');
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.muted));
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.isIncome, required this.onChanged});

  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Spend')),
          ButtonSegment(value: true, label: Text('Income')),
        ],
        selected: {isIncome},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.single),
      );
}

/// Today unless changed. One tap opens the calendar for any day of the past
/// year. A day before the opening date can be logged too, such as a meal
/// forgotten before setting up; it counts as spending but not toward the
/// balance (docs/decisions.md 020).
class _DayTile extends ConsumerWidget {
  const _DayTile({required this.day, required this.onChanged});

  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final yearAgo = DateTime.utc(today.year - 1, today.month, today.day);
    final label = day == today
        ? 'Today'
        : day == DateTime.utc(today.year, today.month, today.day - 1)
            ? 'Yesterday'
            : '${Dates.weekday(day)} ${Dates.short(day)}';
    return DetailTile(
      key: const ValueKey('day-tile'),
      label: 'Day',
      value: label,
      leading: Icon(Icons.event_outlined, color: context.colors.primary),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: day,
          firstDate: yearAgo.isAfter(day) ? day : yearAgo,
          lastDate: today,
          helpText: 'Day of this entry',
        );
        if (picked != null) onChanged(DateTime.utc(picked.year, picked.month, picked.day));
      },
    );
  }
}

class _FavouriteChip extends StatelessWidget {
  const _FavouriteChip({required this.favourite, required this.tint, required this.selected, required this.onTap});

  final Favourite favourite;
  final Tint tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftButton(
      selected: selected,
      onTap: onTap,
      semanticLabel: 'Fill in ${favourite.label}, ${Money.format(favourite.amount)}',
      padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.xs, AppSpacing.m, AppSpacing.xs),
      child: Row(
        children: [
          CategoryBubble(categoryKey: favourite.categoryKey, tint: tint, size: 34),
          const SizedBox(width: AppSpacing.s),
          Text(favourite.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.xs),
          Text(Money.format(favourite.amount), style: TextStyle(color: c.muted, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftButton(
      selected: selected,
      onTap: onTap,
      semanticLabel: category.label,
      radius: AppRadii.control + 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CategoryBubble(categoryKey: category.key, tint: categoryTint(category), size: 36),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: selected ? c.ink : c.muted, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
