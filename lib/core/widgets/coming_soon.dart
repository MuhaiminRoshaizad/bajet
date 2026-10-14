import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// An honest placeholder for a screen planned for a later release.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.l),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: c.primary, size: 28),
                  const SizedBox(height: AppSpacing.m),
                  Text(message, style: TextStyle(color: c.ink, fontSize: 15, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
