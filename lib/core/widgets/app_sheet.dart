import 'package:flutter/material.dart';

/// Opens a bottom sheet the app's way. Flutter's sheet reaches the bottom of
/// the screen whatever the system draws there (bottom_sheet.dart: "extends
/// all the way to the bottom of the screen, including any system
/// intrusions"), so the content is kept above the navigation bar, three
/// buttons or gesture pill, here once rather than in every sheet. The sheet's
/// own colour still runs behind the bar. A sheet's keyboard padding comes on
/// top, and the bar's is gone while the keyboard covers it.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      builder: (context) => SafeArea(top: false, child: builder(context)),
    );
