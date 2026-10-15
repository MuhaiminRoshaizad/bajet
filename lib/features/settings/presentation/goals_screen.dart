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
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

/// What the owner is saving for, funded in priority order.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final achieved = ref.watch(achievedGoalsProvider).value ?? const <Goal>[];
    final outcomes = {for (final o in ref.watch(projectionProvider)?.goals ?? const []) o.goal.id: o};
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('Goals are bought in priority order. Tap one to change or delete it; marking one bought logs its price and moves it out of the plan.', style: TextStyle(color: c.muted)),
          ),
          if (goals.isNotEmpty)
            CardGroup(
              children: [
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) {
                    final ids = [for (final g in goals) g.id];
                    ids.insert(to, ids.removeAt(from));
                    ref.read(planRepositoryProvider).reorderGoals(ids);
                  },
                  children: [
                    // Hold to drag: an immediate drag would lose the gesture
                    // to the page's own scrolling.
                    for (final (i, g) in goals.indexed)
                      ReorderableDelayedDragStartListener(
                        key: ValueKey('goal-${g.id}'),
                        index: i,
                        enabled: goals.length > 1,
                        child: ListTile(
                          minTileHeight: 64,
                          onTap: () => _openForm(context, g),
                          leading: CircleAvatar(backgroundColor: c.keepSurface, foregroundColor: c.keep, child: Text('${i + 1}')),
                          title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${Money.format(g.price)} by ${Dates.full(g.targetDate)}'
                            '${outcomes[g.id] == null ? '' : outcomes[g.id]!.onTrack ? ' · on track' : ' · short'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(onPressed: () => _markBought(context, ref, g), child: const Text('Bought')),
                              if (goals.length > 1)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.m),
                                  child: Icon(Icons.drag_handle_rounded, color: c.muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          if (goals.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.xs, 0),
              child: Text('Hold a goal and drag it to change which is bought first.', style: TextStyle(color: c.muted, fontSize: 13)),
            ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a goal'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
          if (achieved.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxl, AppSpacing.xs, AppSpacing.s),
              child: Text('Done', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
            ),
            CardGroup(
              children: [
                for (final g in achieved)
                  ListTile(
                    minTileHeight: 64,
                    leading: CircleAvatar(backgroundColor: c.goodSurface, foregroundColor: c.good, child: const Icon(Icons.check_rounded)),
                    title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Bought ${Dates.full(g.achievedOn!)} for ${Money.format(g.price)}'),
                    trailing: IconButton(
                      onPressed: () => _deleteGoal(context, ref, g),
                      icon: Icon(Icons.delete_outline_rounded, color: c.muted),
                      tooltip: 'Remove ${g.name} from Done',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markBought(BuildContext context, WidgetRef ref, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${goal.name} as bought?'),
        content: Text('This logs ${Money.format(goal.price)} as spent today and takes the goal out of the plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Mark bought')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(planRepositoryProvider).markGoalBought(goal.id, on: ref.read(todayProvider));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${goal.name} bought. Well saved.')));
    }
  }
}

void _openForm(BuildContext context, Goal? goal) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _GoalForm(goal: goal));

/// Asks, deletes, and offers to undo. A bought goal's purchase entry stays.
Future<bool> _deleteGoal(BuildContext context, WidgetRef ref, Goal goal) async {
  final messenger = ScaffoldMessenger.of(context);
  final bought = goal.achievedOn != null;
  final confirmed = await confirmDelete(
    context,
    title: bought ? 'Remove ${goal.name} from Done?' : 'Delete ${goal.name}?',
    message: bought
        ? 'The purchase stays in History as it was logged.'
        : 'It comes off Runway and Today. Nothing you have logged changes.',
    action: bought ? 'Remove' : 'Delete',
  );
  if (!confirmed) return false;
  final repo = ref.read(planRepositoryProvider);
  await repo.deleteGoal(goal.id);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text('${bought ? 'Removed' : 'Deleted'} ${goal.name}'), action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreGoal(goal))));
  return true;
}

/// Adds a goal, or changes [goal] when one is given.
class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.goal});

  final Goal? goal;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _price = TextEditingController(text: widget.goal == null ? '' : RinggitCentsFormatter.format(widget.goal!.price));
  late DateTime? _date = widget.goal?.targetDate;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      // Nothing is preselected until a day is chosen, so the calendar never
      // suggests a date the owner did not pick.
      initialDate: _date,
      firstDate: DateTime(today.year, today.month, today.day + 1),
      lastDate: DateTime(today.year + 10),
      helpText: 'Buy day',
    );
    if (picked != null) setState(() => _date = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _tried = true);
    if (!ok || _date == null) return;
    final repo = ref.read(planRepositoryProvider);
    final price = RinggitCentsFormatter.parse(_price.text);
    if (widget.goal case final goal?) {
      await repo.updateGoal(goal.copyWith(name: _name.text, price: price, targetDate: _date));
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    // A new goal joins the end of the queue.
    final priority = goals.fold(0, (m, g) => g.priority > m ? g.priority : m) + 1;
    await repo.addGoal(name: _name.text, price: price, targetDate: _date!, priority: priority);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.goal == null ? 'New goal' : 'Edit goal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
              TextFormField(
                controller: _name,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give the goal a name' : null,
                decoration: InputDecoration(
                  labelText: 'Goal',
                  hintText: 'e.g. New laptop',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _price,
                label: 'Price',
                hint: 'e.g. 4,500.00',
                textInputAction: TextInputAction.done,
                validator: (sen) => sen > 0 ? null : 'Enter the price',
              ),
              const SizedBox(height: AppSpacing.l),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(_date == null ? 'Pick a buy day' : 'Buy day ${Dates.full(_date!)}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(color: _tried && _date == null ? c.bad : c.muted),
                ),
              ),
              if (_tried && _date == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.l),
                  child: Text('Pick the day you plan to buy it', style: TextStyle(color: c.bad, fontSize: 12)),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Save goal')),
              if (widget.goal case final goal?) ...[
                const SizedBox(height: AppSpacing.s),
                DeleteButton(
                  label: 'Delete goal',
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (await _deleteGoal(context, ref, goal)) navigator.pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
