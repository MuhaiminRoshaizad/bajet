/// Screens bajet opens itself that belong to another app or to the system:
/// the camera, the file picker, the share sheet and the fingerprint prompt.
/// While one is open, bajet goes to the background, and the app lock must
/// not count that as the user leaving (docs/decisions.md 017).
abstract final class OutsideApp {
  static var _open = 0;

  /// Whether any such screen is open right now.
  static bool get isOpen => _open > 0;

  /// Runs [task], which opens such a screen, and marks it open until it ends.
  static Future<T> run<T>(Future<T> Function() task) async {
    _open++;
    try {
      return await task();
    } finally {
      _open--;
    }
  }
}
