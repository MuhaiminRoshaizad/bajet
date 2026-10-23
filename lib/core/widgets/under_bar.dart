import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// The space a tab's scrolling list leaves after its last row, so the row
/// can scroll clear of the bottom bar floating over it. The shell's
/// Scaffold counts the bar into the bottom padding (extendBody), so the
/// list keeps that padding to itself instead of a SafeArea taking it.
double underBar(BuildContext context) => MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;

/// A page's list padding with the phone's navigation bar added at the end:
/// the list scrolls on behind the bar, as Android draws apps edge to edge,
/// and its last row still ends clear of the three buttons or gesture pill.
/// A list given padding of its own loses the inset Flutter would otherwise
/// add (ScrollView pads by MediaQuery only when its padding is null), so
/// every page that sets padding goes through this.
EdgeInsets clearOfSystemBar(BuildContext context, EdgeInsets padding) => padding.copyWith(bottom: padding.bottom + MediaQuery.paddingOf(context).bottom);

