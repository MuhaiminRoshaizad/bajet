import 'dart:io';
import 'dart:typed_data';

import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/insights/domain/insights.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:bajet/features/report/data/report_pdf.dart';
import 'package:bajet/features/report/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

// Demo figures only.
DateTime d(int m, int day) => DateTime.utc(2026, m, day);
final categories = {for (final c in demoCategories) c.key: c};
final rules = [for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: 'Day', type: DayType.spend, plannedSpend: 1000)];
final entries = [
  Entry(id: 1, day: d(7, 1), isIncome: true, amount: 300000, categoryKey: 'salary', label: 'Salary', accountId: 1),
  Entry(id: 2, day: d(7, 2), isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch', note: 'With team, then "coffee"', accountId: 2),
  Entry(id: 3, day: d(7, 3), isIncome: false, amount: 50000, categoryKey: 'bills', label: 'Rent', accountId: 1),
];
final accounts = [
  Account(id: 1, kind: AccountKind.bank, name: 'Main account', openingBalance: 0, balance: 250000, look: const CardLook(color: 0xFF1F6A96, finish: CardFinish.matte)),
  Account(id: 2, kind: AccountKind.cash, name: 'Cash', nickname: 'Wallet', openingBalance: 0, balance: 8450, look: const CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)),
  Account(id: 3, kind: AccountKind.ewallet, name: 'E-wallet', openingBalance: 0, balance: 5400, look: const CardLook(color: 0xFF007570, finish: CardFinish.matte)),
];
List<AccountLine> lines() => byAccount(accounts, entriesIn(month(), entries));
Insights month() => insights(
      period: InsightsPeriod.month,
      today: d(7, 3),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: entries,
      categories: demoCategories,
      rules: rules,
    );

void main() {
  test('the text report covers totals, categories and the goal', () {
    final goal = GoalOutcome(Goal(id: 1, name: 'Laptop', price: 450000, targetDate: d(10, 1)), 420000, true);
    final text = reportText(i: month(), accounts: lines(), balance: 249200, weeklyCap: 5000, buffer: 50000, categories: categories, goal: goal);
    expect(text, startsWith('bajet report, 01/07/2026 to 03/07/2026\n'));
    expect(text, contains('Balance today: RM2,492.00'));
    expect(text, contains('Money out: RM508.00'));
    expect(text, contains('Kept: RM2,492.00 (83% of what came in)'));
    expect(text, contains('Money out by category:\n- Bills (fixed): RM500.00\n- Food: RM8.00\n'));
    expect(text, contains('- 2 of 2 days within plan'));
    expect(text, contains('Projected left after buying: RM4,200.00 (on track against a RM500.00 buffer)'));
  });

  test('with several accounts the text report gives each one its money in and out and what it holds', () {
    final text = reportText(i: month(), accounts: lines(), balance: 263850, weeklyCap: 5000, buffer: 50000, categories: categories, goal: null);
    expect(
      text,
      contains('By account:\n'
          '- Main account: in RM3,000.00, out RM500.00, now RM2,500.00\n'
          '- Wallet: out RM8.00, now RM84.50\n'
          '- E-wallet: nothing in or out, now RM54.00\n'),
    );
  });

  test('with one account there is no account breakdown to repeat the totals', () {
    final text = reportText(i: month(), accounts: [lines().first], balance: 249200, weeklyCap: 5000, buffer: 50000, categories: categories, goal: null);
    expect(text, isNot(contains('By account')));
  });

  test('the CSV has one row per entry, oldest first, with its account, quoted where needed', () {
    final csv = reportCsv(entriesIn(month(), entries.reversed.toList()), categories, lines());
    expect(csv.split('\r\n'), [
      'date,type,account,category,label,note,amount',
      '2026-07-01,income,Main account,Salary,Salary,,3000.00',
      '2026-07-02,expense,Wallet,Food,Lunch,"With team, then ""coffee""",8.00',
      '2026-07-03,expense,Main account,Bills,Rent,,500.00',
      '',
    ]);
  });

  test('the PDF builds with the bundled font, over several pages if needed', () async {
    ByteData font(String w) => ByteData.sublistView(File('assets/fonts/Figtree-$w.ttf').readAsBytesSync());
    final many = [
      for (var n = 0; n < 120; n++) Entry(id: n, day: d(7, 2), isIncome: false, amount: 100 + n, categoryKey: 'food', label: 'Snack'),
    ];
    final bytes = await reportPdf(
      i: month(),
      entries: many,
      accounts: lines(),
      categories: categories,
      balance: 249200,
      buffer: 50000,
      goal: null,
      regular: font('Regular'),
      bold: font('Bold'),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // The page objects are compressed, so check the file is complete instead.
    expect(String.fromCharCodes(bytes.skip(bytes.length - 8)).trim(), endsWith('%%EOF'));
  });
}
