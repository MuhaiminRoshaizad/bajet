import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../ledger/presentation/category_visuals.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import 'settings_screen.dart';

/// Monthly bills and income. Each falls due on the same day every month and
/// appears on Today to be confirmed when it arrives.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = [...?ref.watch(recurringProvider).value]..sort((a, b) => a.active == b.active ? a.nextDue.compareTo(b.nextDue) : (a.active ? -1 : 1));
    return Scaffold(
      appBar: AppBar(title: const Text('Bills and income'), backgroundColor: c.background),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('Each one repeats monthly. Switch one off to pause it; its past payments stay in History.', style: TextStyle(color: c.muted)),
          ),
          if (items.isNotEmpty)
            SettingsGroup(
              children: [
                for (final item in items)
                  SwitchListTile(
                    value: item.active,
                    onChanged: (v) => ref.read(planRepositoryProvider).setRecurringActive(item.id, active: v),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${item.isIncome ? '+' : '−'}${Money.format(item.amount)} · '
                      '${item.active ? 'next ${Dates.full(item.nextDue)}' : 'paused'}',
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const _RecurringForm()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a bill or income'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm();

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  bool _isIncome = false;
  String? _category;
  DateTime? _nextDue;
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
      initialDate: _nextDue ?? firstAllowed,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      // Monthly items stay on days 1 to 28 so every month has the day.
      selectableDayPredicate: (d) => d.day <= 28,
      helpText: 'Next due',
    );
    if (picked != null) setState(() => _nextDue = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _tried = true);
    if (!ok || _category == null || _nextDue == null) return;
    await ref.read(planRepositoryProvider).addRecurring(
          name: _name.text,
          isIncome: _isIncome,
          amount: RinggitCentsFormatter.parse(_amount.text),
          categoryKey: _category!,
          nextDue: _nextDue!,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((x) => x.isIncome == _isIncome)];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New bill or income', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
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
              TextFormField(
                controller: _name,
                maxLength: 32,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _isIncome ? 'e.g. Salary' : 'e.g. Phone bill',
                  counterText: '',
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.control), borderSide: BorderSide.none),
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
              const SizedBox(height: AppSpacing.l),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(_nextDue == null ? 'Pick the next due date' : 'Next due ${Dates.full(_nextDue!)}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(color: _tried && _nextDue == null ? c.bad : c.line),
                ),
              ),
              if (_tried && _nextDue == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.l),
                  child: Text('Pick when it is next due', style: TextStyle(color: c.bad, fontSize: 12)),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
