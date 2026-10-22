import 'package:bajet/core/widgets/done_bar.dart';
import 'package:bajet/features/insights/presentation/insights_screen.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:bajet/features/plan/domain/listing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

final marketplace = Uri.parse('https://www.facebook.com/marketplace/item/1/');

Future<void> openGoals(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Goals'));
  await tester.pumpAndSettle();
}

/// What the phone's clipboard holds, as Paste reads it.
void copy(WidgetTester tester, String text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') return {'text': text};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

/// The user goes to another app and comes back.
Future<void> leaveAndReturn(WidgetTester tester) async {
  // Through each state in turn, as Android reports them.
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

FakeWorld withListing(FakeWorld w) {
  w.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1), listingUrl: marketplace);
  return w;
}

void main() {
  testWidgets('a listing link is pasted into a goal, with the keyboard down until a field is tapped', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1)));
    await openGoals(tester);
    await tester.tap(find.text('Laptop'));
    await settleUnderBar(tester);
    expect(tester.testTextInput.isVisible, isFalse);

    copy(tester, '  ${marketplace.toString()} ');
    await tester.ensureVisible(find.text('Paste'));
    await tester.tap(find.text('Paste'));
    await settleUnderBar(tester);
    await tester.ensureVisible(find.text('Save goal'));
    await tester.tap(find.text('Save goal'));
    await settleUnderBar(tester);
    expect(world.goals.single.listing, Listing(marketplace));
    expect(find.text('Marketplace listing'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
    expect(find.text('Saved Laptop, with its listing'), findsOneWidget);
  });

  testWidgets('Paste with nothing copied says so under the field, and flags nothing else', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1)));
    await openGoals(tester);
    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Goal'), '');
    copy(tester, '');
    await tester.ensureVisible(find.text('Paste'));
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(find.text("Nothing is copied yet. Copy the listing's link first."), findsOneWidget);
    expect(find.text('Give the goal a name'), findsNothing, reason: 'Paste checks only its own field');
  });

  testWidgets('text that is not a web link is refused with a reason, and nothing is saved', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1)));
    await openGoals(tester);
    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();
    copy(tester, 'laptop 4500 still ok?');
    await tester.ensureVisible(find.text('Paste'));
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(find.text("That is not a web link. Copy the listing's link and paste it here."), findsOneWidget);
    await tester.ensureVisible(find.text('Save goal'));
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(world.goals.single.listing, isNull);
  });

  testWidgets('tapping the listing opens it, and back from it the goal asks whether it is still for sale', (tester) async {
    final world = await pumpApp(tester, seed: withListing);
    await openGoals(tester);
    await tester.tap(find.byKey(const ValueKey('listing-preview')));
    await tester.pumpAndSettle();
    expect(world.links.opened, [marketplace]);

    await leaveAndReturn(tester);
    expect(find.text('Is the Laptop still for sale?'), findsOneWidget);
    await tester.tap(find.text('Sold'));
    await tester.pumpAndSettle();
    expect(world.goals.single.listing, Listing(marketplace, check: ListingCheck.sold, checkedOn: testToday));
    expect(find.text('Sold'), findsOneWidget);
    expect(find.text('Add a new listing'), findsOneWidget);

    // Coming back again without having opened it asks nothing.
    await leaveAndReturn(tester);
    expect(find.text('Is the Laptop still for sale?'), findsNothing);
  });

  testWidgets('a sold listing can be removed, and the removal undone', (tester) async {
    final world = await pumpApp(tester, seed: withListing);
    await openGoals(tester);
    await tester.tap(find.byKey(const ValueKey('listing-preview')));
    await leaveAndReturn(tester);
    await tester.tap(find.text('Sold'));
    await settleUnderBar(tester);

    await tester.tap(find.text('Remove'));
    await settleUnderBar(tester);
    expect(world.goals.single.listing, isNull);
    expect(find.text('Marketplace listing'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect(world.goals.single.listing?.check, ListingCheck.sold);
  });

  testWidgets('the question is asked wherever the user is once back in bajet', (tester) async {
    final world = await pumpApp(tester, seed: withListing);
    await openGoals(tester);
    await tester.tap(find.byKey(const ValueKey('listing-preview')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await leaveAndReturn(tester);
    expect(find.text('Is the Laptop still for sale?'), findsOneWidget);
    await tester.tap(find.text('Still up'));
    await tester.pumpAndSettle();
    expect(world.goals.single.listing?.check, ListingCheck.up);
  });

  testWidgets('a link nothing can open says so', (tester) async {
    final world = await pumpApp(tester, seed: withListing);
    world.links.opens = false;
    await openGoals(tester);
    await tester.tap(find.byKey(const ValueKey('listing-preview')));
    await settleUnderBar(tester);
    expect(find.text('Nothing on this phone could open that link.'), findsOneWidget);
    await leaveAndReturn(tester);
    expect(find.text('Is the Laptop still for sale?'), findsNothing);
  });

  testWidgets('behind the lock, the question waits until the lock is passed', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      withListing(w);
      w.lockSettings.saved = const LockSettings(enabled: true);
      // Passed at launch, then cancelled once back, then passed.
      w.deviceAuth.outcomes = [AuthOutcome.passed, AuthOutcome.cancelled, AuthOutcome.passed];
    });
    await openGoals(tester);
    await tester.tap(find.byKey(const ValueKey('listing-preview')));
    await tester.pumpAndSettle();
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    world.clock = world.clock.add(const Duration(minutes: 2));
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text('bajet is locked'), findsOneWidget);
    expect(find.text('Is the Laptop still for sale?'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('bajet is locked'), findsNothing);
    expect(find.text('Is the Laptop still for sale?'), findsOneWidget);
  });

  testWidgets("Insights' goal card shows the listing, opens it, and asks on the way back", (tester) async {
    // Insights shows its cards once something is logged.
    final world = await pumpApp(tester, seed: (w) => withListing(w).add(EntryDraft(day: testToday, isIncome: false, amount: 1200, categoryKey: 'food')));
    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('listing-preview'));
    await tester.scrollUntilVisible(preview, 300, scrollable: find.descendant(of: find.byType(InsightsScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    expect(find.text('Marketplace listing'), findsOneWidget);
    expect(find.text('Remove'), findsNothing, reason: 'the link is changed in Settings → Goals');

    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(world.links.opened, [marketplace]);
    await leaveAndReturn(tester);
    await tester.tap(find.text('Sold'));
    await tester.pumpAndSettle();
    expect(world.goals.single.listing?.check, ListingCheck.sold);

    // The "Marked sold" bar leaves by itself, uncovering the card.
    await tester.pump(barDuration);
    await tester.pumpAndSettle();
    await tester.drag(find.descendant(of: find.byType(InsightsScreen), matching: find.byType(Scrollable)).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find another listing'));
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsOneWidget);
  });
}
