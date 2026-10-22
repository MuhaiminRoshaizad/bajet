import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/rise_in.dart';
import '../core/widgets/soft.dart';
import '../features/launch/domain/launch_link.dart';
import '../features/launch/presentation/launch_providers.dart';
import '../features/ledger/presentation/ledger_providers.dart';
import '../features/ledger/presentation/log_sheet.dart';
import '../features/settings/presentation/goal_listing.dart';
import 'leave_guard.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab('Today', Icons.home_outlined, Icons.home_rounded),
  _Tab('Runway', Icons.show_chart_rounded, Icons.show_chart_rounded),
  _Tab('Insights', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _Tab('Coach', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
];

/// The four top-level destinations behind one floating bottom bar, with the
/// logger's button beside it. Each branch keeps its own stack and scroll
/// position.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // A launcher shortcut opens the logger, filled in from a favourite
    // when the link names one. Fires at once too, for a link that started
    // the app before the shell existed.
    ref.listenManual(pendingLaunchProvider, (_, link) {
      if (link != null) WidgetsBinding.instance.addPostFrameCallback((_) => _open(link));
    }, fireImmediately: true);
  }

  Future<void> _open(LaunchLink link) async {
    ref.read(pendingLaunchProvider.notifier).consume();
    if (!mounted) return;
    final id = link.favouriteId;
    final favourite = id == null ? null : (await ref.read(favouriteRepositoryProvider).watchAll().first).where((f) => f.id == id).firstOrNull;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await showLogSheet(
      context,
      prefill: favourite == null ? null : LogPrefill(amount: favourite.amount, categoryKey: favourite.categoryKey, label: favourite.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return LeaveGuard(
      onToday: navigationShell.currentIndex == 0,
      goToday: () {
        ref.read(screenEntryProvider.notifier).arrive();
        navigationShell.goBranch(0);
      },
      child: ListingCheckHost(
        child: Scaffold(
          // The page runs on under the bar, which floats over it; each tab's
          // list ends with room to scroll its last row clear (underBar).
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: _FloatingBar(
            index: navigationShell.currentIndex,
            onTab: (i) {
              ref.read(screenEntryProvider.notifier).arrive();
              navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
            },
          ),
        ),
      ),
    );
  }
}

/// The four tabs in a soft pill and, beside it, the one way to log: a
/// moulded round button under the thumb. Nothing fills the space around
/// them, so the page shows on every side.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.index, required this.onTab});

  final int index;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.s),
        // Only as tall as the bar; a tablet keeps a phone-sized bar rather
        // than one stretched across.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              children: [
                Expanded(child: _TabPill(index: index, onTab: onTab)),
                const SizedBox(width: AppSpacing.m),
                MouldedButton(
                  key: const ValueKey('add'),
                  size: _barHeight,
                  semanticLabel: 'Log spending or income',
                  onTap: () => showLogSheet(context),
                  child: Icon(Icons.add_rounded, size: 30, color: c.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _barHeight = 64.0;

/// The tabs, with the open one pressed into the pill. The hollow springs
/// across to a newly opened tab, passing it by a little before it settles.
class _TabPill extends StatefulWidget {
  const _TabPill({required this.index, required this.onTab});

  final int index;
  final ValueChanged<int> onTab;

  @override
  State<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<_TabPill> with SingleTickerProviderStateMixin {
  /// Where the hollow is, in tabs from the left.
  late final _at = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());

  @override
  void didUpdateWidget(_TabPill old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    final to = widget.index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _at.value = to;
    } else {
      _at.animateWith(SpringSimulation(AppMotion.spring, _at.value, to, _at.velocity, snapToEnd: true));
    }
  }

  @override
  void dispose() {
    _at.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const inset = 6.0;
    return Container(
      height: _barHeight,
      padding: const EdgeInsets.symmetric(horizontal: inset),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(AppRadii.pill), boxShadow: floatingShadows(c)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tab = constraints.maxWidth / _tabs.length;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _at,
                builder: (context, child) {
                  final (left, width) = _hollowSpan(_at.value, tab);
                  return Positioned(left: left, width: width, top: inset, bottom: inset, child: child!);
                },
                child: const SoftWell(key: ValueKey('tab-hollow'), radius: AppRadii.pill, padding: EdgeInsets.zero),
              ),
              // The pill's full height, so each tab sits in the middle of the
              // hollow rather than at the top of the pill.
              Positioned.fill(
                child: Row(
                  children: [
                    for (final (i, t) in _tabs.indexed)
                      Expanded(child: _TabButton(key: ValueKey('tab-${t.label}'), tab: t, selected: widget.index == i, onTap: () => widget.onTab(i))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Where the hollow starts and how wide it is, [at] tabs from the left. Past
/// the first or last tab the spring's overshoot squashes it against the end
/// of the pill, by up to a third of its width, rather than carrying it out
/// of the pill to be cut off.
(double, double) _hollowSpan(double at, double tab) {
  final last = _tabs.length - 1.0;
  final full = tab - 4;
  final over = at < 0 ? -at : (at > last ? at - last : 0.0);
  final width = full - math.min(over * tab, full / 3);
  final left = at < 0 ? 2.0 : (at > last ? last * tab + 2 + full - width : at * tab + 2);
  return (left, width);
}

/// One tab: its icon gives a small bounce as the tab opens.
class _TabButton extends StatefulWidget {
  const _TabButton({super.key, required this.tab, required this.selected, required this.onTap});

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);
  late final _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.94), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_TabButton old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && !MediaQuery.disableAnimationsOf(context)) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tab = widget.tab;
    final selected = widget.selected;
    final color = selected ? c.primary : c.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: widget.onTap,
        radius: 30,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(scale: _scale, child: Icon(selected ? tab.selectedIcon : tab.icon, size: 22, color: color)),
              const SizedBox(height: 2),
              // One line that shrinks to fit, so a large system font or a
              // narrow phone never pushes the label out of the bar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
