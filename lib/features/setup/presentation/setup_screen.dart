import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../accounts/presentation/card_designer.dart';
import '../../backup/presentation/restore_flow.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/plan_repository.dart';
import '../../plan/presentation/plan_providers.dart';

/// First run: where money is kept, with what each place holds now; the
/// weekly allowance; then an optional first goal. Saving settings is what
/// lets the router leave this screen.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _moneyForm = GlobalKey<FormState>();
  final _goalForm = GlobalKey<FormState>();
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
    for (final c in [_cap, _buffer, _goalName, _goalPrice]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_moneyForm.currentState!.validate()) setState(() => _step = 2);
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
      openingDate: ref.read(todayProvider),
      weeklyCap: cap,
      buffer: RinggitCentsFormatter.parse(_buffer.text),
    ));
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      // Nothing is preselected until a day is chosen, so the calendar never
      // suggests a date the user did not pick.
      initialDate: _goalDate,
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
    return Scaffold(
      appBar: _step > 0
          ? AppBar(
              backgroundColor: c.background,
              leading: BackButton(onPressed: () => setState(() => _step--)),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text('Step ${_step + 1} of 3', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.s),
                Text(
                  switch (_step) { 0 => 'Where do you keep your money?', 1 => 'Your week', _ => 'Your first goal' },
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  switch (_step) {
                    0 => "Add every place you hold money, with what's in it right now: your wallet, banks and e-wallets. You need at least one, and can add more later.",
                    1 => 'What you allow yourself each week. You can change it later in Settings.',
                    _ => 'Something you are saving for. bajet works out whether you will get there with money to spare. You can skip this.',
                  },
                  style: TextStyle(color: c.muted, height: 1.45),
                ),
                const SizedBox(height: AppSpacing.xxl),
                switch (_step) { 0 => _accountsStep(), 1 => _moneyStep(), _ => _goalStep() },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountsStep() {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
              decoration: BoxDecoration(color: c.well, borderRadius: BorderRadius.circular(AppRadii.small)),
              child: Row(children: [
                CircleAvatar(backgroundColor: Color(a.look.color), radius: 8),
                const SizedBox(width: AppSpacing.m),
                Expanded(child: Text(a.nickname == null ? a.name : '${a.name} · ${a.nickname}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(Money.format(a.balance), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
              ]),
            ),
          ),
        if (accounts.isNotEmpty) const SizedBox(height: AppSpacing.s),
        AccountKindTiles(onPick: (kind) => showNewAccount(context, kind)),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: accounts.isEmpty ? null : () => setState(() => _step = 1),
          style: _buttonStyle(),
          child: Text(accounts.isEmpty ? 'Add an account to continue' : 'Continue'),
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
    );
  }

  Widget _moneyStep() => Form(
        key: _moneyForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
