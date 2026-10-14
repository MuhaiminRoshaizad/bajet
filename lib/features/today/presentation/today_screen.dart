import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rise_in.dart';
import '../../ledger/presentation/entry_tile.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/projection.dart';
import '../../plan/presentation/plan_providers.dart';
import 'today_providers.dart';
import 'weekly_ring.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final balance = ref.watch(balanceProvider);
    if (balance.hasError) return const _ReadError();

    final settings = ref.watch(settingsProvider).value;
    final rule = ref.watch(todayRuleProvider);
    final days = ref.watch(weekDaysProvider);
    final weekSpent = ref.watch(weekSpentProvider);
    final projection = ref.watch(projectionProvider);
    final goals = ref.watch(goalsProvider).value;
    final due = ref.watch(dueRecurringProvider);
    final entries = ref.watch(recentEntriesProvider).value;
    final categories = {for (final c in ref.watch(categoriesProvider).value ?? const []) c.key: c};

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.xxl),
        children: [
          _Header(today: today),
          const SizedBox(height: AppSpacing.m),
          RiseIn(
            spacing: AppSpacing.m,
            children: [
              _BalanceCard(balance: balance.value, rule: rule),
              for (final item in due) _DueCard(item: item),
              if (days != null && weekSpent != null && settings != null)
                _Card(child: WeeklyRing(days: days, spent: weekSpent, cap: settings.weeklyCap)),
              _GoalCard(outcome: projection?.goals.firstOrNull, hasGoal: goals?.isNotEmpty ?? false, today: today, balance: balance.value),
              _Recent(
                children: [
                  for (final e in (entries ?? const []).take(5))
                    EntryTile(entry: e, category: categories[e.categoryKey], today: today),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            Text('Today', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Spacer(),
            Text('${Dates.weekday(today)} ${Dates.short(today)}', style: TextStyle(color: context.colors.muted)),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l + 2),
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: dark && color == null ? Border.all(color: c.line) : null,
        boxShadow: dark || color != null
            ? null
            : [BoxShadow(color: c.ink.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -12)],
      ),
      child: child,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.rule});

  final int? balance;
  final WeeklyRule? rule;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance', style: TextStyle(color: c.muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          // Counts to a new balance after a log, so the change is visible.
          TweenAnimationBuilder<double>(
            tween: Tween(end: (balance ?? 0).toDouble()),
            duration: animate ? AppMotion.enter : Duration.zero,
            curve: AppMotion.ease,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                balance == null ? '—' : Money.format(value.round()),
                semanticsLabel: balance == null ? 'Balance loading' : 'Balance ${Money.format(balance!)}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -1.5, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          if (rule != null) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Text(
                rule!.plannedSpend > 0 ? '${rule!.label} · up to ${Money.format(rule!.plannedSpend)}' : '${rule!.label} · no spending planned',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DueCard extends ConsumerWidget {
  const _DueCard({required this.item});

  final RecurringItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${item.isIncome ? 'Expected' : 'Due'} ${Dates.full(item.nextDue)} · ${Money.format(item.amount)}', style: TextStyle(color: c.muted, fontSize: 13)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => ref.read(planRepositoryProvider).confirmRecurring(item.id, paidOn: ref.read(todayProvider)),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(item.isIncome ? 'Received' : 'Paid'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.outcome, required this.hasGoal, required this.today, required this.balance});

  final GoalOutcome? outcome;
  final bool hasGoal;
  final DateTime today;
  final int? balance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final o = outcome;
    if (o == null) {
      return _Card(
        color: c.primarySoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hasGoal ? 'Working out buy day…' : 'No goal yet', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (!hasGoal) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Set one up to see what is left on buy day.', style: TextStyle(color: c.muted)),
            ],
          ],
        ),
      );
    }
    final daysLeft = o.goal.targetDate.difference(today).inDays;
    final saved = ((balance ?? 0) / o.goal.price).clamp(0.0, 1.0);
    return _Card(
      color: c.keepSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${o.goal.name} · buy day', style: TextStyle(color: c.keep, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
              _StatusPill(onTrack: o.onTrack),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text('$daysLeft ${daysLeft == 1 ? 'day' : 'days'}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          Text('${Dates.full(o.goal.targetDate)} · ${Money.format(o.leftAfterBuying)} left after buying', style: TextStyle(color: c.keep)),
          const SizedBox(height: AppSpacing.m),
          Semantics(
            label: '${(saved * 100).round()} percent of the price saved',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(value: saved, minHeight: 10, color: c.keep, backgroundColor: c.keep.withValues(alpha: 0.18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.onTrack});

  final bool onTrack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, icon, text) = onTrack
        ? (c.goodSurface, c.good, Icons.check_rounded, 'On track')
        : (c.badSurface, c.bad, Icons.priority_high_rounded, 'Short');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.xs, AppSpacing.s),
          child: Text('Recent', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
        ),
        _Card(
          child: children.isEmpty
              ? Text('Nothing logged yet. Tap + to log your first spend.', style: TextStyle(color: c.muted))
              : Column(children: [for (final (i, w) in children.indexed) ...[if (i > 0) Divider(color: c.line), w]]),
        ),
      ],
    );
  }
}

class _ReadError extends StatelessWidget {
  const _ReadError();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            "bajet couldn't read its data. Close the app fully and open it again; your entries are still on the phone.",
            style: TextStyle(color: context.colors.bad),
          ),
        ),
      );
}
