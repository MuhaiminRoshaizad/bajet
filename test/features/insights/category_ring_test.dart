import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/insights/presentation/category_ring.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

final _categories = {for (final c in demoCategories) c.key: c};

final _today = DateTime.utc(2026, 7, 15);

/// One entry per category for its whole amount, unless [entries] are given.
Future<void> pumpRing(WidgetTester tester, List<(String, int)> byCategory, {List<Entry>? entries, ValueChanged<Entry>? onOpen}) {
  var id = 0;
  return tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: CategoryRing(
          byCategory: byCategory,
          categories: _categories,
          entries: entries ?? [for (final (key, amount) in byCategory) Entry(id: ++id, day: _today, isIncome: false, amount: amount, categoryKey: key)],
          today: _today,
          onOpenEntry: onOpen ?? (_) {},
        ),
      ),
    ),
  ));
}

Entry spent(int id, int day, int amount, String key, String label) =>
    Entry(id: id, day: DateTime.utc(2026, 7, day), isIncome: false, amount: amount, categoryKey: key, label: label);

final _food = [for (var n = 1; n <= 7; n++) spent(n, 8 + n, 100 * n, 'food', 'Lunch $n')];

Finder labelled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

void main() {
  testWidgets('the key gives each category its amount and share, and marks fixed ones', (tester) async {
    await pumpRing(tester, [('food', 18640), ('bills', 12000), ('transport', 6400)]);
    await tester.pumpAndSettle();
    expect(find.text('RM370.40'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('32%'), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
    expect(labelled('Bills RM120.00'), findsOneWidget);
  });

  testWidgets('every amount and share ends on the right edge, however long the name', (tester) async {
    await pumpRing(tester, [('food', 18640), ('bills', 12000), ('transport', 6400)]);
    await tester.pumpAndSettle();
    final edge = tester.getTopRight(find.byType(CategoryRing)).dx;
    final shares = [for (final share in ['50%', '32%', '17%']) tester.getTopRight(find.text(share)).dx];
    expect(shares.toSet(), hasLength(1), reason: 'one column');
    // Only the open-and-close arrow sits past them, on the edge itself.
    expect(tester.getTopRight(find.byIcon(Icons.expand_more_rounded).first).dx, moreOrLessEquals(edge, epsilon: 0.5));
  });

  testWidgets('past six categories the smallest share one slice', (tester) async {
    final keys = [for (final c in demoCategories.where((c) => c.key != untrackedCategoryKey).take(7)) c.key];
    await pumpRing(tester, [for (final (n, k) in keys.indexed) (k, 1000 - n * 100)]);
    await tester.pumpAndSettle();
    expect(labelled('Everything else RM9.00'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.value != null && w.properties.value!.endsWith('%')), findsNWidgets(6));
  });

  testWidgets('it settles on its size after a small bounce past it', (tester) async {
    await pumpRing(tester, [('food', 1000)]);
    double scale() => tester.widget<Transform>(find.descendant(of: find.byType(CategoryRing), matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis();
    var most = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (scale() > most) most = scale();
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(1.0));
    expect(scale(), closeTo(1.0, 0.001));
  });

  testWidgets('tapping a row opens its entries, newest first, and tapping again closes them', (tester) async {
    await pumpRing(tester, [('food', 2800), ('transport', 600)], entries: [..._food.reversed, spent(20, 9, 600, 'transport', 'Fuel')]);
    await tester.pumpAndSettle();
    expect(find.text('Lunch 7'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ring-row-Food')));
    await tester.pumpAndSettle();
    // The middle names it; five show, newest first, then the rest on asking.
    expect(find.descendant(of: find.byType(CategoryRing), matching: find.text('82% · 7 entries')), findsOneWidget);
    expect([for (final t in tester.widgetList<Text>(find.textContaining('Lunch '))) t.data], ['Lunch 7', 'Lunch 6', 'Lunch 5', 'Lunch 4', 'Lunch 3']);
    expect(find.text('Fuel'), findsNothing);
    await tester.tap(find.text('Show all 7'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lunch '), findsNWidgets(7));

    await tester.tap(find.byKey(const ValueKey('ring-row-Food')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lunch '), findsNothing);
    expect(find.text('Money out'), findsOneWidget);
  });

  testWidgets('tapping a slice opens it, another switches, and the middle closes it', (tester) async {
    await pumpRing(tester, [('food', 3000), ('transport', 1000)], entries: [spent(1, 9, 3000, 'food', 'Groceries'), spent(2, 9, 1000, 'transport', 'Fuel')]);
    await tester.pumpAndSettle();
    final ring = tester.getRect(find.byType(GestureDetector).first);
    // Food runs clockwise from the top; transport is the last quarter, on the left.
    await tester.tapAt(ring.topCenter + const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
    await tester.tapAt(ring.centerLeft + const Offset(10, -10));
    await tester.pumpAndSettle();
    expect((find.text('Groceries').evaluate().length, find.text('Fuel').evaluate().length), (0, 1));
    await tester.tapAt(ring.center);
    await tester.pumpAndSettle();
    expect(find.text('Fuel'), findsNothing);
  });

  testWidgets('the open slice springs out past its place and settles', (tester) async {
    await pumpRing(tester, [('food', 3000), ('transport', 1000)]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ring-row-Food')));
    double pop() {
      final painter = tester.widgetList<CustomPaint>(find.descendant(of: find.byType(CategoryRing), matching: find.byType(CustomPaint))).map((p) => p.painter).whereType<CustomPainter>().first;
      return ((painter as dynamic).slices as List).first.$3 as double;
    }
    var most = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (pop() > most) most = pop();
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(1.0));
    expect(pop(), closeTo(1.0, 0.001));
  });

  testWidgets('an entry opens through the ring, and Everything else lists each with its category', (tester) async {
    Entry? opened;
    final keys = [for (final c in demoCategories.where((c) => c.key != untrackedCategoryKey).take(7)) c.key];
    final entries = [for (final (n, k) in keys.indexed) spent(n + 1, 9, 1000 - n * 100, k, 'Thing $n')];
    await pumpRing(tester, [for (final e in entries) (e.categoryKey, e.amount)], entries: entries, onOpen: (e) => opened = e);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ring-row-Everything else')));
    await tester.pumpAndSettle();
    expect(find.text('Thing 5'), findsOneWidget);
    expect(find.text('Thing 6'), findsOneWidget);
    expect(find.text('Thing 0'), findsNothing);
    await tester.tap(find.text('Thing 6'));
    expect(opened?.id, 7);
  });
}
