import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/ledger_models.dart';

const _icons = <String, IconData>{
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'pets': Icons.pets_rounded,
  'family': Icons.family_restroom_rounded,
  'gifts': Icons.card_giftcard_rounded,
  'bills': Icons.receipt_long_rounded,
  'personal': Icons.shopping_bag_rounded,
  'salary': Icons.payments_rounded,
  'kwsp': Icons.savings_rounded,
  'refund': Icons.undo_rounded,
};

/// Categories are data the user can add to, so unknown keys fall back to a
/// neutral icon rather than failing.
IconData categoryIcon(String key) => _icons[key] ?? Icons.more_horiz_rounded;

Tint categoryTint(Category? category) =>
    Tint.values.asNameMap()[category?.tint] ?? Tint.neutral;

/// A rounded tinted square with the category's icon.
class CategoryBubble extends StatelessWidget {
  const CategoryBubble({super.key, required this.categoryKey, required this.tint, this.size = 40});

  final String categoryKey;
  final Tint tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.tintFill(tint), borderRadius: BorderRadius.circular(size * 0.35)),
      child: Icon(categoryIcon(categoryKey), size: size * 0.5, color: c.tintInk(tint)),
    );
  }
}
