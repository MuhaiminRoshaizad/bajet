import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/card_group.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/plan_repository.dart';
import '../../coach/presentation/coach_providers.dart';
import '../../lock/presentation/app_lock_sheet.dart';
import '../../lock/presentation/lock_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import 'balance_sheet.dart';

/// Every amount and rule the app works from, so none of it is fixed in code.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final balance = ref.watch(balanceProvider).value;
    final favourites = ref.watch(favouritesProvider).value?.length ?? 0;
    final accounts = ref.watch(accountsProvider).value?.length ?? 0;
    final weekPlan = ref.watch(rulesProvider).value?.fold(0, (s, r) => s + r.plannedSpend);
    final active = [...?ref.watch(recurringProvider).value?.where((r) => r.active)];
    final income = active.where((r) => r.isIncome).length;
    final bills = active.length - income;
    final spendingDays = ref.watch(rulesProvider).value?.where((r) => r.type != DayType.zero).length;
    final goals = ref.watch(goalsProvider).value?.length ?? 0;
    final events = ref.watch(eventsProvider).value?.where((e) => !e.done).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          CardGroup(
            label: 'Your plan',
            children: [
              SettingsRow(
                icon: Icons.account_balance_wallet_outlined,
                tint: Tint.sage,
                title: 'Balance',
                value: balance == null ? '' : Money.format(balance),
                onTap: () => showBalanceSheet(context),
              ),
              SettingsRow(
                icon: Icons.credit_card_outlined,
                tint: Tint.apricot,
                title: 'Accounts',
                value: accounts == 0 ? '' : '$accounts ${accounts == 1 ? 'account' : 'accounts'} · cards and colours',
                onTap: () => context.push(Routes.accountSettings),
              ),
              SettingsRow(
                icon: Icons.savings_outlined,
                tint: Tint.sky,
                title: 'Allowance and buffer',
                value: settings == null
                    ? ''
                    : '${Money.formatWhole(settings.weeklyCap)} a week${settings.buffer == 0 ? '' : ' · keep ${Money.formatWhole(settings.buffer)}'}',
                onTap: settings == null ? null : () => _editAllowance(context, settings),
              ),
              SettingsRow(
                icon: Icons.calendar_view_week_rounded,
                tint: Tint.teal,
                title: 'Weekly rhythm',
                value: weekPlan == null || spendingDays == null
                    ? ''
                    : '${Money.formatWhole(weekPlan)} over $spendingDays ${spendingDays == 1 ? 'day' : 'days'}',
                onTap: () => context.push(Routes.rhythm),
              ),
              SettingsRow(
                icon: Icons.flag_outlined,
                tint: Tint.apricot,
                title: 'Goals',
                value: goals == 0 ? 'None yet' : '$goals active',
                onTap: () => context.push(Routes.goals),
              ),
              SettingsRow(
                icon: Icons.autorenew_rounded,
                tint: Tint.sage,
                title: 'Bills and income',
                value: active.isEmpty
                    ? 'None yet'
                    : [if (bills > 0) '$bills ${bills == 1 ? 'bill' : 'bills'}', if (income > 0) '$income income'].join(' · '),
                onTap: () => context.push(Routes.recurring),
              ),
              SettingsRow(
                icon: Icons.event_outlined,
                tint: Tint.rose,
                title: 'Planned events',
                value: events == 0 ? 'None yet' : '$events coming',
                onTap: () => context.push(Routes.events),
              ),
              SettingsRow(
                icon: Icons.star_outline_rounded,
                tint: Tint.olive,
                title: 'Favourites',
                value: favourites == 0 ? 'None yet' : '$favourites saved',
                onTap: () => context.push(Routes.favourites),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          CardGroup(
            label: 'Keeping track',
            children: [
              SettingsRow(icon: Icons.fact_check_outlined, tint: Tint.sky, title: 'Sunday check-in', value: 'Match your bank', onTap: () => context.push(Routes.checkin)),
              SettingsRow(icon: Icons.ios_share_rounded, tint: Tint.teal, title: 'Share a report', value: 'Text, PDF or CSV', onTap: () => context.push(Routes.report)),
              SettingsRow(icon: Icons.backup_outlined, tint: Tint.neutral, title: 'Backup', value: 'Export or restore', onTap: () => context.push(Routes.backup)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          CardGroup(
            label: 'App',
            children: [
              SettingsRow(
                icon: Icons.forum_outlined,
                tint: Tint.pink,
                title: 'Coach',
                value: ref.watch(coachKeyProvider).value == null ? 'Add your key' : 'Key saved',
                onTap: () => context.push(Routes.coachKey),
              ),
              SettingsRow(
                icon: Icons.lock_outline_rounded,
                tint: Tint.sky,
                title: 'App lock',
                value: lockSummary(ref.watch(lockSettingsProvider)),
                onTap: () => showAppLockSheet(context),
              ),
              SettingsRow(
                icon: Icons.contrast_rounded,
                tint: Tint.neutral,
                title: 'Appearance',
                value: _themeNames[ref.watch(themeModeProvider)]!,
                onTap: () => showModalBottomSheet<void>(context: context, useSafeArea: true, builder: (_) => const _AppearanceSheet()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editAllowance(BuildContext context, PlanSettings settings) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AllowanceSheet(settings: settings),
      );
}

const _themeNames = {ThemeMode.system: 'Match the phone', ThemeMode.light: 'Light', ThemeMode.dark: 'Dark'};

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s, 0, AppSpacing.s, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text('Appearance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.s),
            RadioGroup<ThemeMode>(
              groupValue: ref.watch(themeModeProvider),
              onChanged: (mode) {
                if (mode == null) return;
                ref.read(themeModeProvider.notifier).choose(mode);
                Navigator.of(context).pop();
              },
              child: const Column(
                children: [
                  RadioListTile(value: ThemeMode.system, title: Text('Match the phone'), subtitle: Text('Light or dark as the phone is set')),
                  RadioListTile(value: ThemeMode.light, title: Text('Light')),
                  RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                ],
              ),
            ),
          ],
        ),
      );
}

/// One destination in Settings: a tinted icon, its name, and what it holds
/// now on a second line, so the value has room and is not squeezed against
/// the edge.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.tint, required this.title, required this.value, this.onTap});

  final IconData icon;
  final Tint tint;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.tintFill(tint), borderRadius: BorderRadius.circular(AppRadii.small)),
        child: Icon(icon, size: 22, color: c.tintInk(tint)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: value.isEmpty ? null : Text(value, style: TextStyle(color: c.muted)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
      onTap: onTap,
    );
  }
}

class _AllowanceSheet extends ConsumerStatefulWidget {
  const _AllowanceSheet({required this.settings});

  final PlanSettings settings;

  @override
  ConsumerState<_AllowanceSheet> createState() => _AllowanceSheetState();
}

class _AllowanceSheetState extends ConsumerState<_AllowanceSheet> {
  final _form = GlobalKey<FormState>();
  late final _cap = TextEditingController(text: RinggitCentsFormatter.format(widget.settings.weeklyCap));
  late final _buffer = TextEditingController(text: widget.settings.buffer == 0 ? '' : RinggitCentsFormatter.format(widget.settings.buffer));

  @override
  void dispose() {
    _cap.dispose();
    _buffer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = widget.settings;
    await ref.read(planRepositoryProvider).saveSettings(PlanSettings(
          openingDate: s.openingDate,
          weeklyCap: RinggitCentsFormatter.parse(_cap.text),
          buffer: RinggitCentsFormatter.parse(_buffer.text),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Allowance and buffer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
}
