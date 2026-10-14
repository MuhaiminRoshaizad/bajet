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

/// One-off future money: a service, a gift, a bonus that may or may not come.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final events = [...?ref.watch(eventsProvider).value?.where((e) => !e.done)]..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Planned events')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('Mark one done when it happens, and log the money as usual.', style: TextStyle(color: c.muted)),
          ),
          if (events.isNotEmpty)
            SettingsGroup(
              children: [
                for (final e in events)
                  ListTile(
                    minTileHeight: 60,
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${e.isIncome ? '+' : '−'}${Money.format(e.amount)} · ${Dates.full(e.date)}${e.countInProjection ? '' : ' · not counted'}',
                    ),
                    trailing: TextButton(
                      onPressed: () => ref.read(planRepositoryProvider).setEventDone(e.id, done: true),
                      child: const Text('Done'),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const _EventForm()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add an event'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm();

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  bool _isIncome = false;
  bool _counted = true;
  String? _category;
  DateTime? _date;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(today.year, today.month, today.day + 7),
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 5),
      helpText: 'When',
    );
    if (picked != null) setState(() => _date = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _tried = true);
    if (!ok || _category == null || _date == null) return;
    await ref.read(planRepositoryProvider).addEvent(
          name: _name.text,
          isIncome: _isIncome,
          amount: RinggitCentsFormatter.parse(_amount.text),
          categoryKey: _category!,
          date: _date!,
          countInProjection: _counted,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((x) => x.isIncome == _isIncome && !x.isAutomatic)];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New event', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: false, label: Text('Expense')), ButtonSegment(value: true, label: Text('Income'))],
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
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _isIncome ? 'e.g. Year-end bonus' : 'e.g. Car service',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _amount,
                label: 'Amount',
                hint: 'e.g. 250.00',
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
                label: Text(_date == null ? 'Pick the date' : Dates.full(_date!)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(color: _tried && _date == null ? c.bad : c.muted),
                ),
              ),
              if (_tried && _date == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.l),
                  child: Text('Pick when it happens', style: TextStyle(color: c.bad, fontSize: 12)),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Count it in the plan'),
                subtitle: const Text('Turn off for money that may not come, so the plan does not rely on it.'),
                value: _counted,
                onChanged: (v) => setState(() => _counted = v),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Save event')),
            ],
          ),
        ),
      ),
    );
  }
}
