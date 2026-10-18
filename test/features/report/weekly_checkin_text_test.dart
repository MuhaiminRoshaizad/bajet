import 'package:bajet/core/money/money.dart';
import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/report/domain/weekly_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checkin_fixtures.dart';

void main() {
  test('a week ahead of its target reads verdict first, with the goal judged apart', () {
    final w = checkin(entries: week, checkins: [lastWeek]);
    final left = w.goal!.leftAfterBuying;
    expect((w.verdict, w.difference, w.goalSafe), (WeekVerdict.onTrack, 401745 - 392000, true));
    expect(weeklyCheckinText(w).split('\n'), [
      'bajet · weekly check-in · Mon 19/10 – Sun 25/10/2026',
      '',
      'CHECK-IN: ON TRACK ✓ · goal SAFE',
      'Balance RM4,017.45 vs target RM3,920.00 (+RM97.45)',
      'Bank match: not checked yet · untracked RM0.00',
      '',
      'THIS WEEK',
      'Spent RM21.50 of RM30.00 (RM8.50 under)',
      '  Food RM15.50 · Transport RM6.00',
      'Days: 6 of 6 finished days within plan · 2 no-spend days',
      '  Today counts once it is over',
      'Rules: Fast (Mon) kept · Flex (Thu) kept · Rest (Sat) kept',
      '',
      'GOAL · Laptop · RM3,000.00 · Sat 09/01/2027 (76 days)',
      'Left after buying: ${Money.format(left)} (+${Money.format(left - 170000)} since last check-in)',
      'With unconfirmed income: ${Money.format(left + 30000)}',
      'Buffer RM1,000.00: SAFE',
      '',
      'NEXT 7 DAYS',
      'Fri 30/10   Birthday dinner      −RM100.00',
      'Sun 01/11   Salary               +RM2,384.45',
      'Sun 01/11   Bills                −RM1,839.89',
      'Next check-in: Sun 01/11, stay above ${Money.format(w.nextTarget)}',
    ]);
    // Monday to Saturday at plan, today's plan of nothing, then next week's
    // first six days, the dinner and the 1st's pay and bills.
    expect(w.nextTarget, 401745 - 10000 - 3000 + 238445 - 183989);
  });

  test('a week short of its target says so, and ends on what went wrong', () {
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
    final text = weeklyCheckinText(w);
    expect(text, contains('CHECK-IN: SHORT RM4.20 this week · goal still SAFE'));
    expect(text, contains('Balance RM3,915.80 vs target RM3,920.00 (−RM4.20)'));
    expect(text, contains('Bank match: not checked yet · untracked RM12.50'));
    expect(text, contains('Days: 4 of 6 finished days within plan'));
    expect(text, endsWith('FLAGS\n- RM12.50 untracked, found at this check-in\n- Wed and Fri went over their plan'));
  });

  test('the first check-in says how many days it covers and names the starting adjustment', () {
    final w = checkin(
      today: d(10, 18),
      opening: d(10, 16),
      entries: [spend(d(10, 16), 550, 'food'), spend(d(10, 18), 1230, untrackedCategoryKey, 'Starting adjustment')],
    );
    final text = weeklyCheckinText(w).split('\n');
    expect(w.verdict, WeekVerdict.baseline);
    expect(text.take(6), [
      'bajet · weekly check-in · Mon 12/10 – Sun 18/10/2026',
      'First check-in · 3 days of data (16/10–18/10)',
      '',
      'CHECK-IN: BASELINE SET · goal SAFE (${Money.format(w.goal!.leftAfterBuying)} left after buying)',
      'Balance RM4,017.45 · target for Sun 25/10 set when the check-in is finished',
      'Bank match: not checked yet · starting adjustment RM12.30 (not counted as untracked)',
    ]);
    expect(text, contains('Spent RM5.50 of RM6.00 planned for these days (RM0.50 under)'));
    expect(text.where((l) => l.startsWith('Left after buying')).single, isNot(contains('since last check-in')));
    expect(text, isNot(contains('FLAGS')));
  });

  test('a saved check-in today gives the bank match and the next target', () {
    final today = Checkin(checkedOn: sunday, balance: 401745, matched: true, untracked: 0, allowanceSpent: 2150, leftAfterBuying: 170850, nextTarget: 443000);
    final w = checkin(entries: week, checkins: [today, lastWeek]);
    final text = weeklyCheckinText(w);
    expect(text, contains('Bank match: yes · untracked RM0.00'));
    expect(text, contains('Next check-in: Sun 01/11, stay above RM4,430.00'));
    expect(w.target, 392000);
  });

  test('a later baseline is not called the first check-in', () {
    final early = Checkin(checkedOn: d(10, 17), balance: 403000, matched: true, allowanceSpent: 0, leftAfterBuying: 170000, nextTarget: 392000);
    final w = checkin(entries: week, checkins: [early]);
    expect((w.verdict, w.first), (WeekVerdict.baseline, false));
    expect(weeklyCheckinText(w), isNot(contains('First check-in')));
  });

  test('midweek the text shows the target still to come and judges nothing', () {
    final text = weeklyCheckinText(checkin(today: d(10, 21), entries: week.where((e) => !e.day.isAfter(d(10, 21))).toList(), checkins: [lastWeek]));
    expect(text, contains('CHECK-IN: IN PROGRESS · goal SAFE\nBalance RM4,017.45 · target RM3,920.00 on Sun 25/10\n'));
    expect(text, contains('Next check-in: Sun 25/10, stay above RM3,920.00'));
  });
}
