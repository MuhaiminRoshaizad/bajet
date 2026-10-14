import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../backup/presentation/restore_flow.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/plan_repository.dart';
import '../../plan/presentation/plan_providers.dart';

/// First run: the starting balance and weekly allowance, then an optional
/// first goal. Saving settings is what lets the router leave this screen.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _moneyForm = GlobalKey<FormState>();
  final _goalForm = GlobalKey<FormState>();
  final _balance = TextEditingController();
  final _cap = TextEditingController();
  final _buffer = TextEditingController();
  final _goalName = TextEditingController();
  final _goalPrice = TextEditingController();
  DateTime? _goalDate;
  bool _goalDateMissing = false;
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_balance, _cap, _buffer, _goalName, _goalPrice]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_moneyForm.currentState!.validate()) setState(() => _step = 1);
  }

  bool get _goalStarted => _goalName.text.trim().isNotEmpty || _goalPrice.text.isNotEmpty || _goalDate != null;

  Future<void> _finish({required bool withGoal}) async {
    if (withGoal) {
      final fieldsOk = _goalForm.currentState!.validate();
      setState(() => _goalDateMissing = _goalDate == null);
      if (!fieldsOk || _goalDate == null) return;
    }
    setState(() => _saving = true);
    final repo = ref.read(planRepositoryProvider);
    if (withGoal) {
      await repo.addGoal(name: _goalName.text, price: RinggitCentsFormatter.parse(_goalPrice.text), targetDate: _goalDate!);
    }
    // Start the weekly rhythm from the allowance, so a first lunch is not
    // judged against a plan of nothing. Each day can be changed later.
    final cap = RinggitCentsFormatter.parse(_cap.text);
    final daily = spreadOverWeek(cap);
    for (final rule in await repo.watchRules().first) {
      await repo.saveRule(WeeklyRule(weekday: rule.weekday, label: rule.label, type: rule.type, plannedSpend: daily[rule.weekday - 1]));
    }
    // Saved last: settings existing is what moves the router on to Today.
    await repo.saveSettings(PlanSettings(
      openingBalance: RinggitCentsFormatter.parse(_balance.text),
      openingDate: ref.read(todayProvider),
      weeklyCap: cap,
      buffer: RinggitCentsFormatter.parse(_buffer.text),
    ));
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _goalDate ?? DateTime(today.year, today.month + 3, today.day),
      firstDate: DateTime(today.year, today.month, today.day + 1),
      lastDate: DateTime(today.year + 10),
      helpText: 'Buy day',
    );
    if (picked != null) {
      setState(() {
        _goalDate = DateTime.utc(picked.year, picked.month, picked.day);
        _goalDateMissing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _step == 1
            ? AppBar(
                backgroundColor: c.background,
                leading: BackButton(onPressed: () => setState(() => _step = 0)),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text('Step ${_step + 1} of 2', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.s),
                  Text(_step == 0 ? 'Your money' : 'Your first goal', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    _step == 0
                        ? 'Where you are today and what you allow yourself each week. You can change all of it later in Settings.'
                        : 'Something you are saving for. bajet works out whether you will get there with money to spare. You can skip this.',
                    style: TextStyle(color: c.muted, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_step == 0) _moneyStep() else _goalStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moneyStep() => Form(
        key: _moneyForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoneyField(
              controller: _balance,
              label: 'Balance today',
              hint: 'e.g. 2,500.00',
              helper: 'Everything you have across your accounts right now.',
              validator: (sen) => sen > 0 ? null : 'Enter your balance today',
            ),
            const SizedBox(height: AppSpacing.l),
            MoneyField(
              controller: _cap,
              label: 'Weekly allowance',
              hint: 'e.g. 50.00',
              helper: 'What you let yourself spend Monday to Sunday on food, transport and extras. Bills and other fixed costs do not count.',
              validator: (sen) => sen > 0 ? null : 'Enter how much you allow each week',
            ),
            const SizedBox(height: AppSpacing.l),
            MoneyField(
              controller: _buffer,
              label: 'Keep at least (optional)',
              hint: 'e.g. 1,000.00',
              helper: 'The least you want left in your account after buying a goal. A goal is on track only if this much remains. Leave empty for none.',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: _next,
              style: _buttonStyle(),
              child: const Text('Continue'),
            ),
            const SizedBox(height: AppSpacing.s),
            // A restore saves settings too, which moves the router on to Today.
            TextButton.icon(
              onPressed: () => pickAndRestore(context, ref, replacing: false),
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restore from a backup file instead'),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      );

  Widget _goalStep() {
    final c = context.colors;
    return Form(
      key: _goalForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _goalName,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 40,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Give the goal a name' : null,
            onChanged: (_) => setState(() {}),
            decoration: _decoration('Goal', 'e.g. New laptop'),
          ),
          const SizedBox(height: AppSpacing.s),
          MoneyField(
            controller: _goalPrice,
            label: 'Price',
            hint: 'e.g. 4,500.00',
            validator: (sen) => sen > 0 ? null : 'Enter the price',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.l),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_goalDate == null ? 'Pick a buy day' : 'Buy day ${Dates.full(_goalDate!)}'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              alignment: Alignment.centerLeft,
              side: BorderSide(color: _goalDateMissing ? c.bad : c.muted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
            ),
          ),
          if (_goalDateMissing)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.l),
              child: Text('Pick the day you plan to buy it', style: TextStyle(color: c.bad, fontSize: 12)),
            ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: _saving ? null : () => _finish(withGoal: true),
            style: _buttonStyle(),
            child: const Text('Start'),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: _saving || _goalStarted ? null : () => _finish(withGoal: false),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_goalStarted ? 'Clear the goal to skip it' : 'Skip for now'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control + 4)),
      );

  InputDecoration _decoration(String label, String hint) => InputDecoration(labelText: label, hintText: hint, counterText: '');
}
