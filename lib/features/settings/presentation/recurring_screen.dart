import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/presentation/account_choice.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/category_visuals.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

/// Monthly bills and income. Each falls due on the same day every month, or
/// within a window of days for pay and bills that move around, and appears
/// on Today to be confirmed when it arrives.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = [...?ref.watch(recurringProvider).value]..sort((a, b) => a.active == b.active ? a.nextDue.compareTo(b.nextDue) : (a.active ? -1 : 1));
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};
    final income = items.where((r) => r.isIncome).toList();
    final bills = items.where((r) => !r.isIncome).toList();
    int monthly(List<RecurringItem> list) => list.where((r) => r.active).fold(0, (s, r) => s + r.amount);
    final left = monthly(income) - monthly(bills);

    Widget group(String label, List<RecurringItem> list, {required bool isIncome}) => CardGroup(
          label: label,
          labelTrailing: Text(
            '${isIncome ? '+' : '−'}${Money.format(monthly(list))} a month',
            style: TextStyle(color: isIncome ? c.good : c.muted, fontWeight: FontWeight.w700, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          children: [for (final item in list) _RecurringRow(item: item, category: categories[item.categoryKey])],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Bills and income')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.xl),
            child: Text('Each one repeats monthly. Tap one to change or pause it; its past payments stay in History.', style: TextStyle(color: c.muted)),
          ),
          if (income.isNotEmpty) ...[group('Income', income, isIncome: true), const SizedBox(height: AppSpacing.xxl)],
          if (bills.isNotEmpty) ...[group('Bills', bills, isIncome: false), const SizedBox(height: AppSpacing.l)],
          if (income.isNotEmpty && bills.isNotEmpty) ...[
            SoftWell(
              radius: AppRadii.control,
              child: Row(
                children: [
                  const Expanded(child: Text('Left after bills', style: TextStyle(fontWeight: FontWeight.w700))),
                  Text(
                    '${left < 0 ? '−' : ''}${Money.format(left.abs())} a month',
                    style: TextStyle(fontWeight: FontWeight.w700, color: left < 0 ? c.bad : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          FilledButton.icon(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a bill or income'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}

/// One bill or income: its category, name and when it next lands, with the
/// amount on the right. A paused one is dimmed and says so.
class _RecurringRow extends StatelessWidget {
  const _RecurringRow({required this.item, required this.category});

  final RecurringItem item;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = categoryTint(category);
    return Opacity(
      opacity: item.active ? 1 : 0.55,
      child: ListTile(
        minTileHeight: 68,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        onTap: () => _openForm(context, item),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.tintFill(tint), borderRadius: BorderRadius.circular(AppRadii.small)),
          child: Icon(categoryIcon(item.categoryKey), size: 22, color: c.tintInk(tint)),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item.active ? 'Next ${Dates.span(item.nextDue, item.windowEnd)}' : 'Paused', style: TextStyle(color: c.muted)),
        trailing: Text(
          '${item.isIncome ? '+' : '−'}${Money.format(item.amount)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: item.isIncome ? c.good : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}

void _openForm(BuildContext context, RecurringItem? item) =>
    showAppSheet<void>(context: context, isScrollControlled: true, builder: (_) => _RecurringForm(item: item));

/// Adds a new item, or changes [item] when one is given.
class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.item});

  final RecurringItem? item;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _amount = TextEditingController(text: widget.item == null ? '' : RinggitCentsFormatter.format(widget.item!.amount));
  late bool _isIncome = widget.item?.isIncome ?? false;
  late String? _category = widget.item?.categoryKey;
  late DateTime? _nextDue = widget.item?.nextDue;

  /// The last day it may land when [_varies]; null for a fixed day.
  late DateTime? _lastDay = (widget.item?.windowDays ?? 0) > 0 ? widget.item!.windowEnd : null;
  late bool _varies = _lastDay != null;
  late bool _active = widget.item?.active ?? true;

  /// Where it is paid from or into; null means the first account.
  late int? _accountId = widget.item?.accountId;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final firstAllowed = today.day <= 28 ? today : DateTime.utc(today.year, today.month + 1, 1);
    final picked = await showDatePicker(
      context: context,
      // An overdue item's date has passed and cannot be picked again.
      initialDate: _nextDue == null || _nextDue!.isBefore(firstAllowed) ? firstAllowed : _nextDue,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      // Monthly items stay on days 1 to 28 so every month has the day.
      selectableDayPredicate: (d) => d.day <= 28,
      helpText: 'Next due',
    );
    if (picked != null) setState(() => _nextDue = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _pickWindow() async {
    final today = ref.read(todayProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      currentDate: today,
      helpText: 'Earliest and latest day',
      saveText: 'Done',
      // The first day repeats monthly, so it stays on days 1 to 28; the
      // window closes before the next month's opens.
      selectableDayPredicate: (day, start, end) {
        if (start == null || end != null) return day.day <= 28;
        return !day.isBefore(start) && day.difference(start).inDays <= maxWindowDays;
      },
    );
    if (picked != null) {
      setState(() {
        _nextDue = DateTime.utc(picked.start.year, picked.start.month, picked.start.day);
        _lastDay = DateTime.utc(picked.end.year, picked.end.month, picked.end.day);
      });
    }
  }

  bool get _whenMissing => _nextDue == null || (_varies && _lastDay == null);

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _tried = true);
    if (!ok || _category == null || _whenMissing) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(planRepositoryProvider);
    final name = _name.text.trim();
    final amount = RinggitCentsFormatter.parse(_amount.text);
    final window = _varies ? _lastDay!.difference(_nextDue!).inDays : 0;
    final item = widget.item;
    if (item == null) {
      final id = await repo.addRecurring(name: name, isIncome: _isIncome, amount: amount, categoryKey: _category!, nextDue: _nextDue!, windowDays: window, accountId: _accountId);
      if (mounted) Navigator.of(context).pop();
      showBar(messenger, 'Added $name', undo: () => repo.deleteRecurring(id));
      return;
    }
    await repo.updateRecurring(item.copyWith(name: name, amount: amount, categoryKey: _category, nextDue: _nextDue, windowDays: window, accountId: _accountId));
    if (_active != item.active) await repo.setRecurringActive(item.id, active: _active);
    if (mounted) Navigator.of(context).pop();
    showBar(messenger, _active == item.active ? 'Saved $name' : _active ? 'Counting $name again' : 'Paused $name', undo: () async {
      await repo.updateRecurring(item);
      if (_active != item.active) await repo.setRecurringActive(item.id, active: item.active);
    });
  }

  Future<void> _delete() async {
    final item = widget.item!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await confirmDelete(
      context,
      title: 'Delete ${item.name}?',
      message: 'It stops repeating and comes off Runway. Payments you already confirmed stay in History. To stop it for a while instead, switch off Counted each month.',
    );
    if (!confirmed) return;
    final repo = ref.read(planRepositoryProvider);
    final removal = await repo.deleteRecurring(item.id);
    navigator.pop();
    showBar(messenger, 'Deleted ${item.name}', undo: () => repo.restoreRecurring(removal));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((x) => x.isIncome == _isIncome && !x.isAutomatic)];
    final accounts = ref.watch(accountsProvider).value ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                switch (widget.item?.isIncome) { null => 'New bill or income', true => 'Edit income', false => 'Edit bill' },
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.l),
              if (widget.item == null) ...[
                SegmentedButton<bool>(
                  segments: const [ButtonSegment(value: false, label: Text('Bill')), ButtonSegment(value: true, label: Text('Income'))],
                  selected: {_isIncome},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    _isIncome = s.single;
                    _category = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              TextFormField(
                controller: _name,
                maxLength: 32,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _isIncome ? 'e.g. Salary' : 'e.g. Phone bill',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _amount,
                label: 'Amount each month',
                hint: 'e.g. 45.00',
                textInputAction: TextInputAction.done,
                validator: (sen) => sen > 0 ? null : 'Enter the amount',
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tried && _category == null ? c.bad : c.muted)),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final cat in categories)
                    ChoiceChip(
                      label: Text(cat.label),
                      avatar: Icon(categoryIcon(cat.key), size: 18),
                      selected: _category == cat.key,
                      onSelected: (_) => setState(() => _category = cat.key),
                    ),
                ],
              ),
              if (_tried && _category == null)
                Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Pick a category', style: TextStyle(color: c.bad, fontSize: 12))),
              // Confirming it logs the payment to this account.
              if (accounts.length > 1) ...[
                const SizedBox(height: AppSpacing.l),
                AccountChoice(
                  label: _isIncome ? 'Paid into' : 'Paid from',
                  accounts: accounts,
                  selected: accounts.any((a) => a.id == _accountId) ? _accountId : accounts.first.id,
                  onSelect: (id) => setState(() => _accountId = id),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('The day changes each month'),
                subtitle: Text(_isIncome
                    ? 'Give the earliest and latest day it arrives. Runway counts it on the latest.'
                    : 'Give the earliest and latest day it goes out. Runway counts it on the earliest.'),
                value: _varies,
                onChanged: (v) => setState(() {
                  _varies = v;
                  _nextDue = null;
                  _lastDay = null;
                }),
              ),
              const SizedBox(height: AppSpacing.s),
              OutlinedButton.icon(
                onPressed: _varies ? _pickWindow : _pickDate,
                icon: Icon(_varies ? Icons.date_range_outlined : Icons.event_outlined),
                label: Text(switch ((_varies, _whenMissing)) {
                  (false, true) => 'Pick the next due date',
                  (false, false) => 'Next due ${Dates.full(_nextDue!)}',
                  (true, true) => 'Pick the earliest and latest day',
                  (true, false) => 'Next between ${Dates.span(_nextDue!, _lastDay!)}',
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(color: _tried && _whenMissing ? c.bad : c.muted),
                ),
              ),
              if (_tried && _whenMissing)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.l),
                  child: Text(_varies ? 'Pick the days it can land on' : 'Pick when it is next due', style: TextStyle(color: c.bad, fontSize: 12)),
                ),
              if (widget.item != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Counted each month'),
                  subtitle: const Text('Switch off to pause it. Runway leaves it out until it is back on.'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Save')),
              if (widget.item != null) ...[
                const SizedBox(height: AppSpacing.s),
                DeleteButton(label: widget.item!.isIncome ? 'Delete income' : 'Delete bill', onPressed: _delete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
