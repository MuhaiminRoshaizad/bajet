import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// The space a tab's scrolling list leaves after its last row, so the row
/// can scroll clear of the bottom bar floating over it. The shell's
/// Scaffold counts the bar into the bottom padding (extendBody), so the
/// list keeps that padding to itself instead of a SafeArea taking it.
double underBar(BuildContext context) => MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;
