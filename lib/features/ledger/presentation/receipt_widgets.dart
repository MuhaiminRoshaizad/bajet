import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/receipt_store.dart';
import 'detail_tile.dart';
import 'ledger_providers.dart';

/// The logger's receipt tile: None until one is attached, then a thumbnail.
/// Either way it opens the receipt sheet, to add, replace or remove one.
class ReceiptTile extends ConsumerWidget {
  const ReceiptTile({super.key, required this.receipt, required this.onChanged});

  final String? receipt;
  final ValueChanged<String?> onChanged;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_ReceiptChoice>(
      context: context,
      useSafeArea: true,
      builder: (_) => _ReceiptSheet(receipt: receipt),
    );
    switch (choice) {
      case null:
        return;
      case _ReceiptChoice.remove:
        onChanged(null);
      case _ReceiptChoice.camera || _ReceiptChoice.photos:
        final name = await ref.read(receiptStoreProvider).pick(choice == _ReceiptChoice.camera ? ReceiptSource.camera : ReceiptSource.gallery);
        if (name != null) onChanged(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final name = receipt;
    return DetailTile(
      key: const ValueKey('receipt-tile'),
      label: 'Receipt',
      value: name == null ? 'None' : 'Attached',
      leading: name == null ? Icon(Icons.receipt_long_outlined, color: c.primary) : ReceiptImage(name: name, size: 36),
      onTap: () => _open(context, ref),
    );
  }
}

enum _ReceiptChoice { camera, photos, remove }

/// Where a receipt comes from, as two large tiles in the app's own style,
/// and, once one is attached, a look at it and a way to take it off.
class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.receipt});

  final String? receipt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = receipt;
    Widget source(_ReceiptChoice choice, IconData icon, Tint tint, String title, String subtitle) => Expanded(
          child: SoftButton(
            onTap: () => Navigator.of(context).pop(choice),
            semanticLabel: '$title, $subtitle',
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l, horizontal: AppSpacing.s),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: c.tintFill(tint), borderRadius: BorderRadius.circular(AppRadii.small)),
                  child: Icon(icon, color: c.tintInk(tint)),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12)),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name == null ? 'Add a receipt' : 'Receipt', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.l),
          if (name != null) ...[
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'View the receipt',
                  excludeSemantics: true,
                  child: GestureDetector(onTap: () => showReceipt(context, name), child: ReceiptImage(name: name, size: 64)),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(child: Text('Tap the picture to see it full size, or choose a new one below.', style: TextStyle(color: c.muted, height: 1.4))),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          Row(
            children: [
              source(_ReceiptChoice.camera, Icons.photo_camera_outlined, Tint.sky, 'Camera', 'Take a photo'),
              const SizedBox(width: AppSpacing.m),
              source(_ReceiptChoice.photos, Icons.photo_library_outlined, Tint.teal, 'Photos', 'Photo or screenshot'),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (name == null)
            Text('The picture stays on this phone.', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 13))
          else
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(_ReceiptChoice.remove),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove receipt'),
              style: TextButton.styleFrom(foregroundColor: c.bad, minimumSize: const Size.fromHeight(48)),
            ),
        ],
      ),
    );
  }
}

/// A receipt image, square and rounded at [size], or filling its space when
/// [size] is null.
class ReceiptImage extends ConsumerWidget {
  const ReceiptImage({super.key, required this.name, this.size});

  final String name;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return FutureBuilder<ImageProvider>(
      future: ref.read(receiptStoreProvider).image(name),
      builder: (context, snapshot) {
        final missing = SoftWell(
          radius: AppRadii.small,
          padding: EdgeInsets.zero,
          child: SizedBox(width: size, height: size, child: Icon(Icons.image_not_supported_outlined, color: c.muted)),
        );
        if (!snapshot.hasData) return SizedBox(width: size, height: size);
        final image = Image(
          image: snapshot.data!,
          width: size,
          height: size,
          fit: size == null ? BoxFit.contain : BoxFit.cover,
          // A backup restored on another phone has the name but not the file.
          errorBuilder: (context, error, stack) => missing,
        );
        return size == null ? image : ClipRRect(borderRadius: BorderRadius.circular(AppRadii.small), child: image);
      },
    );
  }
}

/// Shows a receipt full screen, pinch to zoom.
Future<void> showReceipt(BuildContext context, String name) => showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: context.colors.background,
        child: Stack(
          children: [
            Positioned.fill(child: InteractiveViewer(maxScale: 5, child: Center(child: ReceiptImage(name: name)))),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
