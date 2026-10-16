/// Where a launch from outside the app should land. Every launcher shortcut
/// speaks this one link format: `bajet://log`, or
/// `bajet://log?favourite=<id>` to fill one in.
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
