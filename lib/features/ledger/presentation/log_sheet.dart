import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/ledger_models.dart';
import 'category_visuals.dart';
import 'ledger_providers.dart';
import 'receipt_widgets.dart';

/// What to fill the logger with when it opens from somewhere that already
/// knows part of the entry. Nothing is saved until Log is pressed.
class LogPrefill {
  const LogPrefill({this.isIncome = false, this.amount, this.categoryKey, this.label});

  final bool isIncome;
  final int? amount;
  final String? categoryKey;
  final String? label;
}

/// Opens the logger, with [prefill] filled in, or with [editing] the same
/// form filled in with an existing entry. Saving shows a snackbar with undo
/// on [messengerContext]'s scaffold, which outlives the sheet.
Future<void> showLogSheet(BuildContext messengerContext, {Entry? editing, LogPrefill? prefill}) => showModalBottomSheet<void>(
      context: messengerContext,
      isScrollControlled: true,
      useSafeArea: true,
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
  static const _maxDigits = 7; // RM99,999.99

  bool _isIncome = false;
  String _digits = '';
  String? _categoryKey;
  String? _label;
  int? _favouriteId;
  String? _receipt;
  final _note = TextEditingController();
  late DateTime _day = ref.read(todayProvider);
  bool _saving = false;

  int get _amount => int.tryParse(_digits) ?? 0;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _isIncome = e.isIncome;
      _digits = '${e.amount}';
      _categoryKey = e.categoryKey;
      _label = e.label;
      _note.text = e.note ?? '';
      _day = e.day;
      _receipt = e.receipt;
    }
    final p = widget.prefill;
    if (p != null) {
      _isIncome = p.isIncome;
      _digits = p.amount == null ? '' : '${p.amount}';
      _categoryKey = p.categoryKey;
      _label = p.label;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _key(String k) {
    setState(() {
      if (k == 'del') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else {
        final next = (_digits + k).replaceFirst(RegExp(r'^0+'), '');
        if (next.length <= _maxDigits) _digits = next;
      }
      _favouriteId = null;
    });
  }

  void _useFavourite(Favourite f) => setState(() {
        _isIncome = false;
        _favouriteId = f.id;
        _categoryKey = f.categoryKey;
        _label = f.label;
        _digits = '${f.amount}';
      });

  void _pickCategory(String key) => setState(() {
        _categoryKey = key;
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
    );
    final repo = ref.read(ledgerRepositoryProvider);
    final before = widget.editing;
    final String message;
    final VoidCallback undo;
    if (before == null) {
      final id = await repo.add(draft);
      message = '${_isIncome ? 'Added' : 'Logged'} ${_label ?? _categoryLabel(_categoryKey!)} ${Money.format(draft.amount)}';
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
      ));
      message = 'Saved changes';
      undo = () => repo.update(before);
    }
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), action: SnackBarAction(label: 'Undo', onPressed: undo)));
  }

  void _manageFavourites() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.favourites);
  }

  String _categoryLabel(String key) =>
      ref.read(categoriesProvider).value?.firstWhere((c) => c.key == key).label ?? key;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((cat) => cat.isIncome == _isIncome && !cat.isAutomatic)];
    final favourites = ref.watch(favouritesProvider).value ?? const [];
    final ready = _amount > 0 && _categoryKey != null && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                    }),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded), tooltip: 'Close'),
                ],
              ),
            ),
            // The amount and the keys that fill it stay in view; only the
            // choices between them scroll.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.s),
                  // The amount reads out of a display set into the sheet,
                  // like a calculator's, above the keys that fill it.
                  SoftWell(
                    radius: AppRadii.card,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.l),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Amount ${Money.format(_amount)}',
                      excludeSemantics: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Money.format(_amount),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: _amount == 0 ? c.muted : c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Center(child: _PlanHint(amount: _amount, isIncome: _isIncome, categoryKey: _categoryKey, day: _day)),
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
                      childAspectRatio: 1.1,
                      children: [
                        for (final cat in categories)
                          _CategoryTile(category: cat, selected: _categoryKey == cat.key, onTap: () => _pickCategory(cat.key)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    // Full width, so the label is never cut short.
                    TextField(
                      controller: _note,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Lunch with team', counterText: ''),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _DayPicker(day: _day, onChanged: (d) => setState(() => _day = d)),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    ReceiptField(receipt: _receipt, onChanged: (r) => setState(() => _receipt = r)),
                    const SizedBox(height: AppSpacing.s),
                  ],
                ),
              ),
            ),
            // While the system keyboard is up for the note, the keypad
            // steps aside so the note field keeps its room.
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, 0),
                child: _Keypad(onKey: _key),
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
      ),
    );
  }
}

/// Says whether the amount fits the day's planned spend, and by how much it
/// would set the goal back if not. Fixed costs and income get no hint.
class _PlanHint extends ConsumerWidget {
  const _PlanHint({required this.amount, required this.isIncome, required this.categoryKey, required this.day});

  final int amount;
  final bool isIncome;
  final String? categoryKey;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final categories = ref.watch(categoriesProvider).value;
    final rules = ref.watch(rulesProvider).value;
    final entries = ref.watch(recentEntriesProvider).value;
    final category = categories?.where((x) => x.key == categoryKey).firstOrNull;
    if (isIncome || amount == 0 || category == null || category.isFixed || rules == null || entries == null) {
      return const SizedBox(height: 28);
    }
    final fixed = {for (final x in categories!.where((x) => x.isFixed)) x.key};
    final planned = rules.where((r) => r.weekday == day.weekday).firstOrNull?.plannedSpend ?? 0;
    final room = (planned - flexibleSpent(entries, fixed, day, day)).clamp(0, planned);
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

/// Today unless changed. One tap opens the calendar for any day from the
/// opening date, the first day the balance counts, up to today.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.day, required this.onChanged});

  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final opening = ref.watch(settingsProvider).value?.openingDate ?? today;
    final label = day == today
        ? 'Today'
        : day == DateTime.utc(today.year, today.month, today.day - 1)
            ? 'Yesterday, ${Dates.short(day)}'
            : '${Dates.weekday(day)} ${Dates.full(day)}';
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: day,
          firstDate: opening.isAfter(day) ? day : opening,
          lastDate: today,
          helpText: 'Day of this entry',
        );
        if (picked != null) onChanged(DateTime.utc(picked.year, picked.month, picked.day));
      },
      icon: const Icon(Icons.event_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
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

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Room around each key for its shadow.
      padding: const EdgeInsets.all(AppSpacing.xs),
      mainAxisSpacing: AppSpacing.m,
      crossAxisSpacing: AppSpacing.m,
      childAspectRatio: 2.2,
      children: [
        for (final k in keys)
          SoftButton(
            onTap: () => onKey(k),
            child: Center(
              child: k == 'del'
                  ? Icon(Icons.backspace_outlined, color: c.ink, semanticLabel: 'Delete digit')
                  : Text(k, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: c.ink)),
            ),
          ),
      ],
    );
  }
}
