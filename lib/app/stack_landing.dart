import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/presentation/account_providers.dart';
import '../features/accounts/presentation/account_stack.dart';
import '../features/opening/domain/opening_timeline.dart';
import '../features/opening/presentation/opening_providers.dart';

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
