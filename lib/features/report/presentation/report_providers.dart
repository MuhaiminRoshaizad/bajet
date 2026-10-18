import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../insights/presentation/insights_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/projection.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/report.dart';
import '../domain/weekly_checkin.dart';

/// Each account over [range], for the report and the coach. Null until the
/// accounts, the entries and the range's figures have loaded.
final reportAccountsProvider = Provider.family<List<AccountLine>?, InsightsRange>((ref, range) {
  final i = ref.watch(insightsForProvider(range));
  final accounts = ref.watch(accountsProvider).value;
  final all = ref.watch(allEntriesProvider).value;
  if (i == null || accounts == null || all == null) return null;
  return byAccount(accounts, entriesIn(i, all));
});

/// This week's check-in report, or null until everything it reads has
/// loaded.
final weeklyCheckinProvider = Provider<WeeklyCheckin?>((ref) {
  final today = ref.watch(todayProvider);
  final weekOn = DateTime.utc(today.year, today.month, today.day + 7);
  final settings = ref.watch(settingsProvider).value;
  final balance = ref.watch(balanceProvider).value;
  final entries = ref.watch(allEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  final rules = ref.watch(rulesProvider).value;
  final checkins = ref.watch(checkinsProvider).value;
  final projection = ref.watch(projectionThroughProvider(weekOn));
  final unconfirmed = ref.watch(projectionWithProvider(const WhatIf(countUnconfirmed: true)));
  final recurring = ref.watch(recurringProvider).value;
  final events = ref.watch(eventsProvider).value;
  final goals = ref.watch(goalsProvider).value;
  if ([settings, balance, entries, categories, rules, checkins, projection, unconfirmed, recurring, events, goals].contains(null)) return null;
  return weeklyCheckin(
    today: today,
    openingDate: settings!.openingDate,
    weeklyCap: settings.weeklyCap,
    buffer: settings.buffer,
    balance: balance!,
    entries: entries!,
    categories: categories!,
    rules: rules!,
    checkins: checkins!,
    projection: projection!,
    unconfirmed: unconfirmed!,
    recurring: recurring!,
    events: events!,
    goals: goals!,
  );
});
