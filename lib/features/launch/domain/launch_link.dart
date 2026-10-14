/// Where a launch from outside the app should land. The home-screen widget
/// and the launcher shortcuts both speak this one link format:
/// `bajet://log`, or `bajet://log?favourite=<id>` to fill one in.
class LaunchLink {
  const LaunchLink.log({this.favouriteId});

  /// A favourite to fill the logger with; null for an empty logger.
  final int? favouriteId;

  static const scheme = 'bajet';

  Uri toUri() => Uri(scheme: scheme, host: 'log', queryParameters: favouriteId == null ? null : {'favourite': '$favouriteId'});

  /// Null for anything that is not a bajet link, so a stray intent does
  /// nothing.
  static LaunchLink? parse(Uri? uri) {
    if (uri == null || uri.scheme != scheme || uri.host != 'log') return null;
    return LaunchLink.log(favouriteId: int.tryParse(uri.queryParameters['favourite'] ?? ''));
  }

  @override
  bool operator ==(Object other) => other is LaunchLink && other.favouriteId == favouriteId;

  @override
  int get hashCode => favouriteId.hashCode;
}

/// What the home-screen widget shows. Kept short and free of the balance,
/// since a home screen is seen by anyone holding the phone.
class WidgetSnapshot {
  const WidgetSnapshot({required this.weekLine, required this.favourites});

  /// Such as "RM15.80 left this week".
  final String weekLine;

  /// Up to two favourites as (id, label) for one-tap buttons.
  final List<(int, String)> favourites;
}
