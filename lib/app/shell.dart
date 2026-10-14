import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/rise_in.dart';
import '../core/widgets/soft.dart';
import '../features/ledger/presentation/log_sheet.dart';

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

/// The four top-level destinations behind one bottom bar, with the logger's
/// button in the middle. Each branch keeps its own stack and scroll position.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: c.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
            child: Row(
              children: [
                for (final (i, tab) in _tabs.indexed) ...[
                  // The one way to log sits in the middle, under the thumb.
                  if (i == 2) const _AddButton(),
                  Expanded(
                    child: _TabButton(
                      key: ValueKey('tab-${tab.label}'),
                      tab: tab,
                      selected: navigationShell.currentIndex == i,
                      onTap: () {
                        ref.read(screenEntryProvider.notifier).arrive();
                        navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({super.key, required this.tab, required this.selected, required this.onTap});

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.ink : c.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.ease,
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Icon(selected ? tab.selectedIcon : tab.icon, size: 22, color: selected ? c.onPrimary : color),
              ),
              const SizedBox(height: 2),
              // One line that shrinks to fit, so a large system font or a
              // narrow phone never pushes the label out of the bar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      child: SoftButton(
        key: const ValueKey('add'),
        semanticLabel: 'Log spending or income',
        color: c.primary,
        radius: AppRadii.card - 4,
        onTap: () => showLogSheet(context),
        child: SizedBox(width: 58, height: 58, child: Icon(Icons.add_rounded, size: 28, color: c.onPrimary)),
      ),
    );
  }
}
