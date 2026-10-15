import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../ledger/presentation/category_visuals.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

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
            child: Text('Mark one done when it happens, and log the money as usual; a yearly one moves on to next year. Tap one to change or delete it.', style: TextStyle(color: c.muted)),
          ),
          if (events.isNotEmpty)
            CardGroup(
              children: [
                for (final e in events)
                  ListTile(
                    minTileHeight: 60,
                    onTap: () => _openForm(context, e),
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [
                        if (e.spent > 0 && !e.isIncome)
                          '${Money.format(e.spent)} of ${Money.format(e.amount)} spent'
                        else
                          '${e.isIncome ? '+' : '−'}${Money.format(e.amount)}',
                        Dates.full(e.date),
                        if (e.repeatsYearly) 'every year',
                        if (!e.countInProjection) 'not counted',
                      ].join(' · '),
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
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add an event'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}

void _openForm(BuildContext context, PlannedEvent? event) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _EventForm(event: event));

/// Adds an event, or changes [event] when one is given.
class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.event});

  final PlannedEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.event?.name);
  late final _amount = TextEditingController(text: widget.event == null ? '' : RinggitCentsFormatter.format(widget.event!.amount));
  late bool _isIncome = widget.event?.isIncome ?? false;
  late bool _counted = widget.event?.countInProjection ?? true;
  late String? _category = widget.event?.categoryKey;
  late DateTime? _date = widget.event?.date;
  late bool _yearly = widget.event?.repeatsYearly ?? false;
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
      // Nothing is preselected until a day is chosen, so the calendar never
      // suggests a date the owner did not pick.
      initialDate: _date,
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
    final repo = ref.read(planRepositoryProvider);
    final amount = RinggitCentsFormatter.parse(_amount.text);
    if (widget.event case final event?) {
      await repo.updateEvent(event.copyWith(name: _name.text, amount: amount, categoryKey: _category, date: _date, countInProjection: _counted, repeatsYearly: _yearly));
    } else {
      await repo.addEvent(
        name: _name.text,
        isIncome: _isIncome,
        amount: amount,
        categoryKey: _category!,
        date: _date!,
        countInProjection: _counted,
        repeatsYearly: _yearly,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final event = widget.event!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!await confirmDelete(context, title: 'Delete ${event.name}?', message: 'It comes off Runway and Coming up. Anything you have logged for it stays in History.')) return;
    final repo = ref.read(planRepositoryProvider);
    final removal = await repo.deleteEvent(event.id);
    navigator.pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Deleted ${event.name}'), action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreEvent(removal))));
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
              Text(
                switch (widget.event?.isIncome) { null => 'New event', true => 'Edit expected income', false => 'Edit event' },
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.l),
              if (widget.event == null) ...[
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
              ],
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
              const SizedBox(height: AppSpacing.m),
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: false, label: Text('Once')), ButtonSegment(value: true, label: Text('Every year'))],
                selected: {_yearly},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _yearly = s.single),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
                child: Text(
                  _yearly
                      ? 'Comes back on this date each year, like a birthday. Marking it done moves it to next year.'
                      : 'Happens once. Marking it done takes it out of the plan.',
                  style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                ),
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
              if (widget.event != null) ...[
                const SizedBox(height: AppSpacing.s),
                DeleteButton(label: 'Delete event', onPressed: _delete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
