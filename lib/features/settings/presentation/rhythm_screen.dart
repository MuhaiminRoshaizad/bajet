import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';
import 'settings_screen.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _typeLabels = {DayType.zero: 'No spending', DayType.spend: 'Spending', DayType.flex: 'Flexible'};

/// What each weekday usually costs. The projection subtracts these amounts
/// day by day, and the weekly ring judges each day against them.
class RhythmScreen extends ConsumerWidget {
  const RhythmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final rules = ref.watch(rulesProvider).value ?? const <WeeklyRule>[];
    final weekTotal = rules.fold(0, (s, r) => s + r.plannedSpend);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly rhythm'), backgroundColor: c.background),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('What each day usually costs. Planned in total: ${Money.format(weekTotal)} a week.', style: TextStyle(color: c.muted)),
          ),
          SettingsGroup(
            children: [
              for (final r in rules)
                ListTile(
                  minTileHeight: 60,
                  title: Text(_weekdays[r.weekday - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([r.label, _typeLabels[r.type]!, if (r.isFastingDay) 'fasting'].join(' · ')),
                  trailing: Text(Money.format(r.plannedSpend), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(planRepositoryProvider).saveRule(WeeklyRule(
          weekday: widget.rule.weekday,
          label: _label.text.trim(),
          type: _type,
          plannedSpend: RinggitCentsFormatter.parse(_amount.text),
          isFastingDay: _fasting,
        ));
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
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.control), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SegmentedButton<DayType>(
                segments: [for (final t in DayType.values) ButtonSegment(value: t, label: Text(_typeLabels[t]!))],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _type = s.single),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _amount,
                label: 'Planned spend',
                hint: 'e.g. 10.00',
                helper: 'Leave empty for none. The projection subtracts this every week.',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fasting day'),
                subtitle: const Text('Shown with its own mark in the week.'),
                value: _fasting,
                onChanged: (v) => setState(() => _fasting = v),
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
