import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/ledger_models.dart';
import 'category_visuals.dart';
import 'ledger_providers.dart';

/// Opens the logger. Saving shows a snackbar with undo on [messengerContext]'s
/// scaffold, which outlives the sheet.
Future<void> showLogSheet(BuildContext messengerContext) => showModalBottomSheet<void>(
      context: messengerContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LogSheet(messenger: ScaffoldMessenger.of(messengerContext)),
    );

class _LogSheet extends ConsumerStatefulWidget {
  const _LogSheet({required this.messenger});

  final ScaffoldMessengerState messenger;

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
  final _note = TextEditingController();
  late DateTime _day = ref.read(todayProvider);
  bool _saving = false;

  int get _amount => int.tryParse(_digits) ?? 0;

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
    );
    final repo = ref.read(ledgerRepositoryProvider);
    final id = await repo.add(draft);
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    final name = _label ?? _categoryLabel(_categoryKey!);
    Navigator.of(context).pop();
    widget.messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_isIncome ? 'Added' : 'Logged'} $name ${Money.format(draft.amount)}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.delete(id)),
      ));
  }

  String _categoryLabel(String key) =>
      ref.read(categoriesProvider).value?.firstWhere((c) => c.key == key).label ?? key;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((cat) => cat.isIncome == _isIncome)];
    final favourites = ref.watch(favouritesProvider).value ?? const [];
    final ready = _amount > 0 && _categoryKey != null && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.s, 0),
              child: Row(
                children: [
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.s),
                    Semantics(
                      liveRegion: true,
                      label: 'Amount ${Money.format(_amount)}',
                      excludeSemantics: true,
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
                    const SizedBox(height: AppSpacing.s),
                    Center(child: _PlanHint(amount: _amount, isIncome: _isIncome, categoryKey: _categoryKey, day: _day)),
                    if (!_isIncome && favourites.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.l),
                      _SectionLabel('Favourites'),
                      const SizedBox(height: AppSpacing.s),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favourites.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
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
                      mainAxisSpacing: AppSpacing.xs,
                      crossAxisSpacing: AppSpacing.xs,
                      childAspectRatio: 1.05,
                      children: [
                        for (final cat in categories)
                          _CategoryTile(category: cat, selected: _categoryKey == cat.key, onTap: () => _pickCategory(cat.key)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _note,
                            maxLength: 60,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Note (optional)',
                              hintText: 'e.g. Lunch with team',
                              counterText: '',
                              filled: true,
                              fillColor: c.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.control), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        _DayToggle(day: _day, today: ref.read(todayProvider), onChanged: (d) => setState(() => _day = d)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _Keypad(onKey: _key),
                    const SizedBox(height: AppSpacing.s),
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
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control + 4)),
                ),
                child: Text(
                  _amount == 0
                      ? 'Type the amount'
                      : _categoryKey == null
                          ? 'Pick a category'
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
        ? (c.badSurface, c.bad, '${Money.format(over)} over $whose plan')
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

class _DayToggle extends StatelessWidget {
  const _DayToggle({required this.day, required this.today, required this.onChanged});

  final DateTime day;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final yesterday = DateTime.utc(today.year, today.month, today.day - 1);
    return SegmentedButton<DateTime>(
      segments: [
        ButtonSegment(value: today, label: const Text('Today')),
        ButtonSegment(value: yesterday, label: const Text('Yesterday')),
      ],
      selected: {day},
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      onSelectionChanged: (s) => onChanged(s.single),
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
    return Semantics(
      button: true,
      selected: selected,
      label: 'Fill in ${favourite.label}, ${Money.format(favourite.amount)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.xs, AppSpacing.m, AppSpacing.xs),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              CategoryBubble(categoryKey: favourite.categoryKey, tint: tint, size: 34),
              const SizedBox(width: AppSpacing.s),
              Text(favourite.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpacing.xs),
              Text(Money.format(favourite.amount), style: TextStyle(color: c.muted, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
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
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control + 2),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.control + 2),
            border: Border.all(color: selected ? c.primary : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryBubble(categoryKey: category.key, tint: categoryTint(category), size: 36),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: selected ? c.ink : c.muted, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
              ),
            ],
          ),
        ),
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
      mainAxisSpacing: AppSpacing.s - 2,
      crossAxisSpacing: AppSpacing.s - 2,
      childAspectRatio: 2.4,
      children: [
        for (final k in keys)
          Material(
            color: c.background,
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.control),
              onTap: () => onKey(k),
              child: Center(
                child: k == 'del'
                    ? Icon(Icons.backspace_outlined, color: c.ink, semanticLabel: 'Delete digit')
                    : Text(k, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: c.ink)),
              ),
            ),
          ),
      ],
    );
  }
}
