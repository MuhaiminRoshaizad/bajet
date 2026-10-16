import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/account_models.dart';
import 'account_list.dart';
import 'account_providers.dart';
import 'account_stack.dart';
import 'card_designer.dart';
import 'card_face.dart';
import 'move_money_sheet.dart';

/// Where the stack on Today opens: every account, overlapped like a wallet,
/// opening downward as it is scrolled. Arriving, the total lifts away and
/// the cards slide out from behind it, from exactly where they sat on Today,
/// down into their strips; leaving, they slide back behind it.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key, this.from});

  /// Where Today's stack was; without it the page simply fades in.
  final StackPlaces? from;

  static const duration = Duration(milliseconds: 650);
  static const reverseDuration = Duration(milliseconds: 420);

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _scroll = ScrollController();
  final _list = GlobalKey();
  final _page = GlobalKey();
  Animation<double>? _route;

  /// Kept from the start: the screen still clears it while being disposed,
  /// when ref can no longer be read.
  late final AccountsOnTop _onTop = ref.read(accountsOnTopProvider.notifier);

  @override
  void initState() {
    super.initState();
    _onTop;
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.animation;
    if (route != null && route != _route) {
      _route?.removeStatusListener(_onRoute);
      _route = route..addStatusListener(_onRoute);
      // Today's stack hides from the first frame; its cards are flying here.
      if (widget.from != null) WidgetsBinding.instance.addPostFrameCallback((_) => _lend(true));
    }
  }

  void _onRoute(AnimationStatus status) {
    // Gone again: Today's stack shows once its cards have landed back in it.
    if (status == AnimationStatus.dismissed) _lend(false);
  }

  void _lend(bool lent) {
    if (mounted) _onTop.set(lent);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRoute);
    // Leaving by any route at all, Today must have its stack back.
    final onTop = _onTop;
    WidgetsBinding.instance.addPostFrameCallback((_) => onTop.set(false));
    _scroll.dispose();
    super.dispose();
  }

  /// Account [i]'s card in the list, on screen, at the current scroll.
  Rect? _listRect(List<Account> accounts, int i) {
    final box = _list.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final layout = AccountListLayout(accounts: accounts, width: box.size.width);
    return Rect.fromLTWH(0, layout.top(i, _offset), box.size.width, layout.cardHeight).shift(box.localToGlobal(Offset.zero));
  }

  /// Where each card sits on screen now, for the account view to fly it from
  /// and back to.
  Rect? _placeOf(int accountId) {
    final accounts = ref.read(accountsProvider).value ?? const [];
    final i = accounts.indexWhere((a) => a.id == accountId);
    return i < 0 ? null : _listRect(accounts, i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final route = ModalRoute.of(context)!.animation!;
    Animation<double> part(double from, double to) => CurvedAnimation(parent: route, curve: Interval(from, to, curve: Curves.easeOut));
    return AnimatedBuilder(
      animation: route,
      builder: (context, _) {
        final settled = route.status == AnimationStatus.completed || widget.from == null;
        // Material gives the cards in flight the same text style as at rest;
        // without it Flutter falls back to its yellow-underlined debug style.
        return Material(
          type: MaterialType.transparency,
          child: Stack(key: _page, children: [
          // The page's own background, washing over Today.
          Positioned.fill(child: FadeTransition(opacity: part(0, 0.4), child: ColoredBox(color: c.background))),
          FadeTransition(
            opacity: widget.from == null ? route : part(0.25, 0.7),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(title: const Text('Your accounts'), backgroundColor: Colors.transparent),
              body: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.xxl),
                children: [
                  AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, _) => AccountList(
                      key: _list,
                      accounts: accounts,
                      offset: _offset,
                      // In flight from Today, the cards here wait unseen.
                      hidden: settled ? const {} : {for (final a in accounts) a.id},
                      onTap: settled ? (a) => context.push(Routes.account(a.id), extra: _placeOf) : null,
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
          ),
          if (!settled) ..._flight(accounts, route),
          ]),
        );
      },
    );
  }

  /// The total lifting away and every card sliding from Today's stack to its
  /// strip, a little after the one above, with a small bounce on the way in
  /// and none on the way back.
  List<Widget> _flight(List<Account> accounts, Animation<double> route) {
    final from = widget.from!;
    final page = _page.currentContext?.findRenderObject() as RenderBox?;
    if (page == null || !page.hasSize) return const [];
    Rect local(Rect r) => r.shift(-page.localToGlobal(Offset.zero));
    final t = route.value;
    final leaving = route.status == AnimationStatus.reverse;
    final n = accounts.length;
    final step = n < 2 ? 0.0 : 0.25 / (n - 1);
    final look = ref.read(totalCardLookProvider).value ?? const TotalCardLook();
    final lift = Curves.easeOut.transform((t / 0.45).clamp(0.0, 1.0));
    final total = local(from.total).translate(0, -30 * lift);
    return [
      // Later cards on top, as in the list.
      for (var i = 0; i < n; i++)
        () {
          final to = _listRect(accounts, i);
          if (to == null) return const SizedBox.shrink();
          final k = ((t - step * i) / (1 - step * (n - 1))).clamp(0.0, 1.0);
          final e = leaving ? Curves.easeInOutCubic.transform(k) : Curves.easeOutBack.transform(k);
          final r = Rect.lerp(local(from.card(i)), local(to), e)!;
          // Cards that hid behind the total on Today come into sight as they leave it.
          final seen = i < AccountStack.peeks ? 1.0 : (k * 3).clamp(0.0, 1.0);
          return Positioned.fromRect(rect: r, child: IgnorePointer(child: Opacity(opacity: seen, child: AccountCard(account: accounts[i]))));
        }(),
      Positioned.fromRect(
        rect: total,
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - lift,
            child: TotalCard(look: look, balance: ref.read(balanceProvider).value, accounts: accounts),
          ),
        ),
      ),
    ];
  }
}
