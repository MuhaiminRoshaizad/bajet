import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/routes.dart';
import '../features/accounts/presentation/account_providers.dart';
import '../features/accounts/presentation/account_stack.dart';
import '../features/opening/domain/opening_timeline.dart';
import '../features/opening/presentation/opening_providers.dart';
import 'router.dart';

/// Where cards flying into Today's stack land, back to front, looked up
/// once the screen underneath has laid out; null when there is no stack of
/// accounts to land in.
StackTarget? todayStackLanding(WidgetRef ref) {
  final stack = openingStackKey.currentContext?.findRenderObject() as RenderBox?;
  final count = ref.read(accountsProvider).value?.length ?? 0;
  if (stack == null || !stack.hasSize || count == 0) return null;
  final places = StackPlaces(stack.localToGlobal(Offset.zero) & stack.size, count);
  return StackTarget(places.card(1), places.card(0), places.total);
}

/// Takes the app to Today, closing whatever was open over it, and once it
/// has laid out says where its stack is, for the unlock's cards.
Future<StackTarget?> landOnToday(WidgetRef ref) async {
  ref.read(routerProvider).go(Routes.today);
  await WidgetsBinding.instance.endOfFrame;
  return todayStackLanding(ref);
}
