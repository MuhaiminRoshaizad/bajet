import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/soft.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_repository.dart';
import '../../plan/presentation/plan_providers.dart';

/// Every amount and rule the app works from, so none of it is fixed in code.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider).value;
    final favourites = ref.watch(favouritesProvider).value?.length ?? 0;
    final weekPlan = ref.watch(rulesProvider).value?.fold(0, (s, r) => s + r.plannedSpend);
    final recurring = ref.watch(recurringProvider).value?.where((r) => r.active).length ?? 0;
    final goals = ref.watch(goalsProvider).value?.length ?? 0;
    final events = ref.watch(eventsProvider).value?.where((e) => !e.done).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          SettingsGroup(
            children: [
              SettingsRow(
                title: 'Weekly allowance and buffer',
                value: settings == null ? '' : '${Money.formatWhole(settings.weeklyCap)} a week',
                onTap: settings == null ? null : () => _editAllowance(context, settings),
              ),
              SettingsRow(
                title: 'Weekly rhythm',
                value: weekPlan == null ? '' : '${Money.formatWhole(weekPlan)} planned',
                onTap: () => context.push(Routes.rhythm),
              ),
              SettingsRow(title: 'Goals', value: goals == 0 ? 'None yet' : '$goals active', onTap: () => context.push(Routes.goals)),
              SettingsRow(
                title: 'Bills and income',
                value: recurring == 0 ? 'None yet' : '$recurring active',
                onTap: () => context.push(Routes.recurring),
              ),
              SettingsRow(title: 'Planned events', value: events == 0 ? 'None yet' : '$events coming', onTap: () => context.push(Routes.events)),
              SettingsRow(title: 'Favourites', value: favourites == 0 ? 'None yet' : '$favourites saved', onTap: () => context.push(Routes.favourites)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SettingsGroup(children: [SettingsRow(title: 'Backup', value: 'Export or restore', onTap: () => context.push(Routes.backup))]),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('Every amount and rule bajet works from is set here.', style: TextStyle(color: c.muted)),
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

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(AppRadii.card);
    // A raised card whose inside is a Material, so each row's ink ripple
    // paints on it.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: softShadows(c, AppDepth.card)),
      child: Material(
        color: c.background,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [for (final (i, row) in children.indexed) ...[if (i > 0) Divider(color: c.line, indent: AppSpacing.l), row]]),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      minTileHeight: 56,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: c.muted)),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ],
      ),
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
          openingBalance: s.openingBalance,
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
              Text('Weekly allowance and buffer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
