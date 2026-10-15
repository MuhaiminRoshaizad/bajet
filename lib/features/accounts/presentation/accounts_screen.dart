import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';
import 'account_stack.dart';
import 'card_designer.dart';
import 'card_face.dart';
import 'move_money_sheet.dart';

/// Where the stack on Today opens: every account fanned out below the total.
/// Arriving, the stack springs apart with a small bounce; leaving, it folds
/// back up before the page goes.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  /// Shared with Today's stack, so the stack flies up to the top of this page.
  static const heroTag = 'account-stack';

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> with SingleTickerProviderStateMixin {
  late final _spread = AnimationController(vsync: this, duration: const Duration(milliseconds: 650), reverseDuration: const Duration(milliseconds: 380));
  var _leaving = false;
  final _stack = GlobalKey();

  /// Where each card sits on screen, fanned out, for the account view to fly
  /// it from and back to.
  Rect? _placeOf(int accountId) {
    final box = _stack.currentContext?.findRenderObject() as RenderBox?;
    final accounts = ref.read(accountsProvider).value ?? const [];
    final i = accounts.indexWhere((a) => a.id == accountId);
    if (box == null || !box.attached || i < 0) return null;
    return AccountStack.spreadCardRect(i, box.size.width).shift(box.localToGlobal(Offset.zero));
  }

  @override
  void initState() {
    super.initState();
    // Starts once the page has faded in and the stack has landed.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _spread.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _spread.value = 1;
  }

  @override
  void dispose() {
    _spread.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _spread.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final look = ref.watch(totalCardLookProvider).value;
    final balance = ref.watch(balanceProvider).value;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Your accounts'), leading: BackButton(onPressed: _leave)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.xxl, AppSpacing.l, AppSpacing.xxl),
          children: [
            Hero(
              tag: AccountsScreen.heroTag,
              child: AnimatedBuilder(
                animation: _spread,
                builder: (context, _) => AccountStack(
                  key: _stack,
                  accounts: accounts,
                  onAccountTap: _spread.isCompleted ? (a) => context.push(Routes.account(a.id), extra: _placeOf) : null,
                  onTotalTap: _spread.isCompleted ? () => showTotalCardDesigner(context) : null,
                  // Out with a bounce past the resting place, back in without one.
                  spread: _leaving ? Curves.easeInCubic.transform(_spread.value) : Curves.easeOutBack.transform(_spread.value),
                  total: TotalCard(look: look ?? const TotalCardLook(), balance: balance, accounts: accounts, hint: 'tap to restyle'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (accounts.length > 1) ...[
              FilledButton.icon(
                onPressed: () => showMoveMoney(context, fromId: accounts.first.id),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Move money'),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            FilledButton.tonalIcon(onPressed: () => showAddAccount(context), icon: const Icon(Icons.add), label: const Text('Add an account')),
          ],
        ),
      ),
    );
  }
}
