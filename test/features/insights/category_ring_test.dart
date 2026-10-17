import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/insights/presentation/category_ring.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

final _categories = {for (final c in demoCategories) c.key: c};

Future<void> pumpRing(WidgetTester tester, List<(String, int)> byCategory) => tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: CategoryRing(byCategory: byCategory, categories: _categories))),
    ));

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
}
