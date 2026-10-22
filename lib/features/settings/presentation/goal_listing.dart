import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../../lock/presentation/lock_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

/// Hands a link to whichever app views it, such as Facebook's for a
/// Marketplace post; false when nothing could open it.
typedef OpenLink = Future<bool> Function(Uri url);

final openLinkProvider = Provider<OpenLink>((ref) => (url) async {
      try {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } on PlatformException {
        return false;
      }
    });

/// The goal whose listing was opened and not yet answered for, until the
/// user is back and [ListingCheckHost] asks.
class PendingListing extends Notifier<int?> {
  @override
  int? build() => null;

  void opened(int goalId) => state = goalId;

  void answered() => state = null;
}

final pendingListingProvider = NotifierProvider<PendingListing, int?>(PendingListing.new);

/// Opens [goal]'s listing in another app, and remembers to ask about it on
/// the way back; says so when nothing could open it.
Future<void> openListing(BuildContext context, WidgetRef ref, Goal goal) async {
  final messenger = ScaffoldMessenger.of(context);
  if (await ref.read(openLinkProvider)(goal.listing!.url)) {
    ref.read(pendingListingProvider.notifier).opened(goal.id);
  } else {
    showBar(messenger, 'Nothing on this phone could open that link.');
  }
}

/// Asks, wherever the user is once back in bajet, whether the listing they
/// opened is still for sale. Behind the lock it waits until the lock is
/// passed and the app has landed on Today, so the question is never under
/// the lock nor closed with the pages the unlock closes.
class ListingCheckHost extends ConsumerStatefulWidget {
  const ListingCheckHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ListingCheckHost> createState() => _ListingCheckHostState();
}

class _ListingCheckHostState extends ConsumerState<ListingCheckHost> {
  late final AppLifecycleListener _resumed;

  @override
  void initState() {
    super.initState();
    // Just after the resume is handled, so a lock coming down on the way
    // back is seen first.
    _resumed = AppLifecycleListener(onResume: () => Future.microtask(_ask));
    // Passing the lock takes the app to Today, closing pages; the question
    // waits until that has landed.
    ref.listenManual(unlockFlightProvider, (was, flying) {
      if (was == true && !flying) Future.microtask(_ask);
    });
  }

  @override
  void dispose() {
    _resumed.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    if (!mounted) return;
    final id = ref.read(pendingListingProvider);
    if (id == null || ref.read(appLockProvider) || ref.read(unlockFlightProvider)) return;
    ref.read(pendingListingProvider.notifier).answered();
    final goal = (ref.read(goalsProvider).value ?? const <Goal>[]).where((g) => g.id == id).firstOrNull;
    if (goal?.listing == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final check = await askListingCheck(context, goal!);
    if (check == null) return;
    final today = ref.read(todayProvider);
    await ref.read(planRepositoryProvider).checkListing(goal.id, check, on: today);
    showBar(messenger, '${check == ListingCheck.sold ? 'Marked sold' : 'Still up'} · ${Dates.full(today)}');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The message for a listing link that is not a web address, or null.
String? listingLinkError(String? text) =>
    (text ?? '').trim().isEmpty || parseListingUrl(text!) != null ? null : "That is not a web link. Copy the listing's link and paste it here.";

/// The optional link on the goal form. Paste fills it from the clipboard,
/// as Facebook's Share → Copy link leaves it, so no long address is typed.
class ListingLinkField extends StatefulWidget {
  const ListingLinkField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<ListingLinkField> createState() => _ListingLinkFieldState();
}

class _ListingLinkFieldState extends State<ListingLinkField> {
  final _field = GlobalKey<FormFieldState<String>>();

  /// Paste was tapped with nothing on the clipboard.
  bool _nothingCopied = false;

  Future<void> _paste() async {
    final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted) return;
    setState(() => _nothingCopied = copied == null || copied.isEmpty);
    if (_nothingCopied) return;
    widget.controller.text = copied!;
    // Only this field is checked, so the rest of the form is not flagged
    // before Save.
    _field.currentState?.didChange(copied);
    _field.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        key: _field,
        controller: widget.controller,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        validator: listingLinkError,
        onChanged: (_) {
          if (_nothingCopied) setState(() => _nothingCopied = false);
        },
        decoration: InputDecoration(
          labelText: 'Listing link (optional)',
          hintText: "Paste the listing's link",
          helperText: _nothingCopied ? "Nothing is copied yet. Copy the listing's link first." : 'Kept on this phone and in backups. The coach never sees it.',
          suffixIcon: TextButton(key: const ValueKey('listing-paste'), onPressed: _paste, child: const Text('Paste')),
        ),
      );
}

/// A goal's listing as a small preview set into its card: the site, and
/// whether it was still up when last looked at. Tapping opens it; once it
/// has sold, it offers a new link or none.
class ListingPreview extends StatelessWidget {
  const ListingPreview({super.key, required this.listing, required this.onOpen, required this.onReplace, required this.onRemove});

  final Listing listing;
  final VoidCallback onOpen;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sold = listing.check == ListingCheck.sold;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final (label, fill, ink) = switch (listing.check) {
      ListingCheck.up => ('Still up', c.goodSurface, c.good),
      ListingCheck.sold => ('Sold', c.badSurface, c.bad),
      null => ('Not checked', c.line, c.muted),
    };
    final when = listing.checkedOn == null ? 'just added' : Dates.full(listing.checkedOn!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '${listing.title}, $label, $when. Opens it',
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('listing-preview'),
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.control),
              child: SoftWell(
                radius: AppRadii.control,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s + 2),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(AppRadii.small)),
                      child: Icon(Icons.storefront_outlined, size: 20, color: c.muted),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, decoration: sold ? TextDecoration.lineThrough : null, decorationColor: c.muted),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              // The pill springs as the answer changes; the words
                              // say it too, so the colour is never the only sign.
                              AnimatedSwitcher(
                                duration: animate ? const Duration(milliseconds: 380) : Duration.zero,
                                switchInCurve: Curves.easeOutBack,
                                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                                child: Container(
                                  key: ValueKey(label),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 1, vertical: 2),
                                  decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadii.pill)),
                                  child: Text(label, style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Flexible(child: Text(when, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.north_east_rounded, size: 18, color: c.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: animate ? const Duration(milliseconds: 380) : Duration.zero,
          curve: Curves.easeOutBack,
          alignment: Alignment.topCenter,
          child: sold
              // Wraps, so large text sizes put Remove on a line of its own.
              ? Wrap(
                  children: [
                    TextButton(onPressed: onReplace, child: const Text('Add a new listing')),
                    TextButton(onPressed: onRemove, style: TextButton.styleFrom(foregroundColor: c.muted), child: const Text('Remove')),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Asks, once the user is back from the listing, whether it is still up.
/// Null when they would rather not say.
Future<ListingCheck?> askListingCheck(BuildContext context, Goal goal) => showModalBottomSheet<ListingCheck>(
      context: context,
      // Over whichever page is open, the bar included.
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) {
        final c = context.colors;
        Widget answer(ListingCheck check, String label, Color fill, Color ink) => Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(check),
                style: FilledButton.styleFrom(backgroundColor: fill, foregroundColor: ink, minimumSize: const Size.fromHeight(56)),
                child: Text(label),
              ),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Is the ${goal.name} still for sale?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  answer(ListingCheck.up, 'Still up', c.goodSurface, c.good),
                  const SizedBox(width: AppSpacing.s),
                  answer(ListingCheck.sold, 'Sold', c.badSurface, c.bad),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(onPressed: () => Navigator.of(context).pop(), style: TextButton.styleFrom(foregroundColor: c.muted), child: const Text('Not now')),
            ],
          ),
        );
      },
    );
