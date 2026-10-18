import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/report/domain/weekly_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checkin_fixtures.dart';

void main() {
  test('a week ahead of its target is on track, with the goal judged apart', () {
    final w = checkin(entries: week, checkins: [lastWeek]);
    final left = w.goal!.leftAfterBuying;
    expect((w.verdict, w.difference, w.goalSafe), (WeekVerdict.onTrack, 401745 - 392000, true));
    expect((w.spent, w.plan), (2150, 3000));
    expect([for (final c in w.categories) (c.key, c.label, c.amount)], [('food', 'Food', 1550), ('transport', 'Transport', 600)]);
    expect((w.finished.length, w.withinPlan, w.noSpendDays), (6, 6, 2));
    expect([for (final r in w.rules) (r.name, r.kept)], [('Fast (Mon)', true), ('Flex (Thu)', true), ('Rest (Sat)', true)]);
    expect((w.change, w.withUnconfirmed, w.daysToGo), (left - 170000, left + 30000, 76));
    expect([for (final n in w.next) n.name], ['Birthday dinner', 'Salary', 'Bills']);
    // Next week's plan, the dinner and the 1st's pay and bills.
    expect(w.nextTarget, 401745 - 10000 - 3000 + 238445 - 183989);
    expect(w.flags, isEmpty);
  });

  test('a week short of its target flags what went wrong', () {
    final w = checkin(
      balance: 391580,
      checkins: [lastWeek],
      entries: [
        spend(d(10, 20), 550, 'food'),
        spend(d(10, 21), 800, 'food'),
        spend(d(10, 22), 600, 'transport'),
        spend(d(10, 23), 1020, 'food'),
        spend(d(10, 25), 1250, untrackedCategoryKey, 'Untracked'),
      ],
    );
    expect((w.verdict, w.difference, w.goalSafe, w.untracked, w.withinPlan), (WeekVerdict.short, -420, true, 1250, 4));
    expect(w.flags, ['RM12.50 untracked, found at this check-in', 'Wed and Fri went over their plan']);
  });

  test('the first check-in sets the baseline over the days it has, and its gap is a starting adjustment', () {
    final w = checkin(
      today: d(10, 18),
      opening: d(10, 16),
      entries: [spend(d(10, 16), 550, 'food'), spend(d(10, 18), 1230, untrackedCategoryKey, 'Starting adjustment')],
    );
    expect((w.verdict, w.first, w.dataDays, w.plan, w.spent), (WeekVerdict.baseline, true, 3, 600, 550));
    expect((w.startingAdjustment, w.untracked, w.change), (1230, 0, null));
    expect(w.days.map((d) => d.state).toList(), [...List.filled(4, CheckinDayState.noData), CheckinDayState.finished, CheckinDayState.finished, CheckinDayState.today]);
  });

  test('a fasting day is broken only by Food spending', () {
    final monday = d(10, 19);
    bool fastKept(List<Entry> entries) => checkin(entries: entries, checkins: [lastWeek]).rules.firstWhere((r) => r.name == 'Fast (Mon)').kept;
    expect(fastKept([spend(monday, 300, 'transport'), spend(monday, 5000, 'bills')]), isTrue);
    expect(fastKept([spend(monday, 200, 'food')]), isFalse);
  });

  test('a saved check-in today supplies the bank match, the untracked money and the next target', () {
    final today = Checkin(checkedOn: sunday, balance: 401745, matched: true, untracked: 0, allowanceSpent: 2150, leftAfterBuying: 170850, nextTarget: 443000);
    final w = checkin(entries: week, checkins: [today, lastWeek]);
    expect((w.matched, w.untracked, w.nextTarget, w.target), (true, 0, 443000, 392000));
  });

  test('a target saved for another day leaves the week as a new baseline', () {
    final early = Checkin(checkedOn: d(10, 17), balance: 403000, matched: true, allowanceSpent: 0, leftAfterBuying: 170000, nextTarget: 392000);
    final w = checkin(entries: week, checkins: [early]);
    expect((w.verdict, w.first), (WeekVerdict.baseline, false));
  });
}
