import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/soft.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _typeLabels = {DayType.zero: 'No spending', DayType.spend: 'Spending', DayType.flex: 'Flexible'};

/// What each weekday usually costs. The projection subtracts these amounts
/// day by day, and the week strip judges each day against them.
class RhythmScreen extends ConsumerWidget {
  const RhythmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final rules = ref.watch(rulesProvider).value ?? const <WeeklyRule>[];
    final allowance = ref.watch(settingsProvider).value?.weeklyCap;
    final weekTotal = rules.fold(0, (s, r) => s + r.plannedSpend);
    final spendingDays = rules.where((r) => r.type != DayType.zero).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly rhythm')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('What each day usually costs. Planned in total: ${Money.format(weekTotal)} a week.', style: TextStyle(color: c.muted)),
          ),
          if (allowance != null && allowance != weekTotal && spendingDays > 0) ...[
            SoftWell(
              radius: AppRadii.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    weekTotal < allowance
                        ? '${Money.format(allowance - weekTotal)} of your ${Money.format(allowance)} weekly allowance is not planned on any day.'
                        : 'The days plan ${Money.format(weekTotal - allowance)} more than your ${Money.format(allowance)} weekly allowance.',
                    style: TextStyle(color: c.ink, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton.tonal(
                    onPressed: () async {
                      final repo = ref.read(planRepositoryProvider);
                      for (final r in spreadOverSpendingDays(rules, allowance)) {
                        await repo.saveRule(r);
                      }
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: Text('Spread ${Money.format(allowance)} over the $spendingDays spending ${spendingDays == 1 ? 'day' : 'days'}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          CardGroup(
            children: [
              for (final r in rules)
                ListTile(
                  minTileHeight: 60,
                  title: Text(_weekdays[r.weekday - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([r.label, if (r.type != DayType.zero) _typeLabels[r.type]!].join(' · ')),
                  // A pill, not a grey RM0.00, so the days that do spend stand out.
                  trailing: r.type == DayType.zero
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: c.well, borderRadius: BorderRadius.circular(AppRadii.pill)),
                          child: Text(r.isFastingDay ? 'Fasting' : 'No spending', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                        )
                      : Text(Money.format(r.plannedSpend), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _RuleForm(rule: r),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleForm extends ConsumerStatefulWidget {
  const _RuleForm({required this.rule});

  final WeeklyRule rule;

  @override
  ConsumerState<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends ConsumerState<_RuleForm> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.rule.label);
  late final _amount = TextEditingController(text: widget.rule.plannedSpend == 0 ? '' : RinggitCentsFormatter.format(widget.rule.plannedSpend));
  late DayType _type = widget.rule.type;
  late bool _fasting = widget.rule.isFastingDay;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// No-spending days, fasting ones included, plan nothing, so their amount
  /// is fixed at RM0.
  bool get _plansNothing => _type == DayType.zero;

  void _setType(DayType type) => setState(() {
        _type = type;
        if (_plansNothing) _amount.clear();
      });

  void _setFasting(bool fasting) => setState(() {
        _fasting = fasting;
        if (fasting) {
          _type = DayType.zero;
          _amount.clear();
        }
      });

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final changed = WeeklyRule(
      weekday: widget.rule.weekday,
      label: _label.text.trim(),
      type: _type,
      plannedSpend: RinggitCentsFormatter.parse(_amount.text),
      isFastingDay: _fasting,
    );
    final rules = ref.read(rulesProvider).value ?? [widget.rule];
    final repo = ref.read(planRepositoryProvider);
    for (final r in withRule(rules, changed)) {
      await repo.saveRule(r);
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Where this day's old plan goes once it stops spending.
  String? _handOver() {
    if (!_plansNothing || widget.rule.plannedSpend == 0) return null;
    final rules = ref.read(rulesProvider).value ?? const <WeeklyRule>[];
    final others = rules.where((r) => r.weekday != widget.rule.weekday && r.type != DayType.zero).length;
    if (others == 0) return 'No other day spends, so the week plans ${Money.format(widget.rule.plannedSpend)} less.';
    final total = rules.fold(0, (s, r) => s + r.plannedSpend);
    return 'Its ${Money.format(widget.rule.plannedSpend)} moves to the other $others spending ${others == 1 ? 'day' : 'days'}, '
        'so the week still plans ${Money.format(total)}.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_weekdays[widget.rule.weekday - 1], style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
              TextFormField(
                controller: _label,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give the day a name' : null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Office day',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SegmentedButton<DayType>(
                segments: [for (final t in DayType.values) ButtonSegment(value: t, label: Text(_typeLabels[t]!))],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _setType(s.single),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _amount,
                label: 'Planned spend',
                hint: _plansNothing ? '0.00' : 'e.g. 10.00',
                helper: _handOver() ?? (_plansNothing ? 'A no-spending day plans RM0.00.' : 'Leave empty for none. The projection subtracts this every week.'),
                enabled: !_plansNothing,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fasting day'),
                subtitle: const Text('Makes it a no-spending day. Switch it to Spending to plan an amount anyway.'),
                value: _fasting,
                onChanged: _setFasting,
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
