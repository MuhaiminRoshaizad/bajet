import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/receipt_store.dart';
import 'ledger_providers.dart';

/// The logger's receipt row: a button to attach one, or once attached, a
/// thumbnail that opens it full size and a way to take it off.
class ReceiptField extends ConsumerWidget {
  const ReceiptField({super.key, required this.receipt, required this.onChanged});

  final String? receipt;
  final ValueChanged<String?> onChanged;

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ReceiptSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ReceiptSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose a photo or screenshot'),
              onTap: () => Navigator.of(context).pop(ReceiptSource.gallery),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
    if (source == null) return;
    final name = await ref.read(receiptStoreProvider).pick(source);
    if (name != null) onChanged(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final name = receipt;
    if (name == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _attach(context, ref),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Attach a receipt (optional)'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      );
    }
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'View the receipt',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => showReceipt(context, name),
            child: ReceiptImage(name: name, size: 56),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(child: Text('Receipt attached', style: TextStyle(color: c.ink, fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close_rounded), tooltip: 'Remove receipt'),
      ],
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
