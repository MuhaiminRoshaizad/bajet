import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_spacing.dart';
import 'account_list.dart';
import 'account_providers.dart';
import 'card_designer.dart';
import 'move_money_sheet.dart';

/// Where the stack on Today opens: every account, overlapped like a wallet,
/// springing into place as the page arrives and opening downward as it is
/// scrolled. The total stays on Today.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> with SingleTickerProviderStateMixin {
  late final _arrive = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final _scroll = ScrollController();
  final _list = GlobalKey();

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;

  /// Where each card sits on screen now, for the account view to fly it from
  /// and back to.
  Rect? _placeOf(int accountId) {
    final box = _list.currentContext?.findRenderObject() as RenderBox?;
    final accounts = ref.read(accountsProvider).value ?? const [];
    final i = accounts.indexWhere((a) => a.id == accountId);
    if (box == null || !box.attached || i < 0) return null;
    final layout = AccountListLayout(accounts: accounts, width: box.size.width);
    return Rect.fromLTWH(0, layout.top(i, _offset), box.size.width, layout.cardHeight).shift(box.localToGlobal(Offset.zero));
  }

  @override
  void initState() {
    super.initState();
    // Springs into the strips once the page has faded in.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _arrive.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _arrive.value = 1;
  }

  @override
  void dispose() {
    _arrive.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Your accounts')),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.xxl),
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scroll, _arrive]),
            builder: (context, _) => AccountList(
              key: _list,
              accounts: accounts,
              offset: _offset,
              arrived: _arrive.value,
              onTap: _arrive.isCompleted ? (a) => context.push(Routes.account(a.id), extra: _placeOf) : null,
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
    );
  }
}
