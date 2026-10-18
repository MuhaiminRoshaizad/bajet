import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/report/presentation/checkin_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checkin_fixtures.dart';

Future<void> show(WidgetTester tester, Widget card) => tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: card)),
    ));

void main() {
  testWidgets('the card shows the week against the allowance, fasting, untracked money and the goal', (tester) async {
    await show(tester, CheckinCard(w: checkin(entries: week, checkins: [lastWeek])));
    expect(find.textContaining('RM21.50'), findsOneWidget);
    expect(find.text('Fasting 1 of 1 kept'), findsOneWidget);
    expect(find.text('Untracked RM0.00'), findsOneWidget);
    expect(find.text('6 of 6 days within plan'), findsOneWidget);
    expect(find.textContaining('76 days to go · +RM'), findsOneWidget);
    expect(find.textContaining('closer this week'), findsOneWidget);
    expect(tester.getSize(find.byType(CheckinCard)), CheckinCard.size);
  });

  testWidgets('a first check-in says the baseline is set rather than how far it moved', (tester) async {
    await show(tester, CheckinCard(w: checkin(today: d(10, 18), opening: d(10, 16), entries: [spend(d(10, 16), 550, 'food')])));
    expect(find.textContaining('baseline set'), findsOneWidget);
    expect(find.text('SPENT OF PLAN'), findsOneWidget);
  });

  testWidgets('a week that cost the goal says it moved further', (tester) async {
    final rich = Checkin(checkedOn: d(10, 18), balance: 900000, matched: true, allowanceSpent: 0, leftAfterBuying: 900000, nextTarget: 392000);
    await show(tester, CheckinCard(w: checkin(entries: week, checkins: [rich])));
    expect(find.textContaining('further this week'), findsOneWidget);
  });
}
