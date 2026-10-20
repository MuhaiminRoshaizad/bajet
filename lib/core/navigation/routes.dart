/// Route paths, kept apart from the router so features can link to one
/// another without importing the app layer that builds them.
abstract final class Routes {
  static const loading = '/loading';
  static const setup = '/setup';
  static const today = '/today';
  static const history = '/today/history';
  static const checkin = '/today/checkin';
  static const accounts = '/today/accounts';

  /// One account, upright, among the others to swipe through.
  static String account(int id) => '/today/accounts/$id';
  static const settings = '/today/settings';
  static const accountSettings = '/today/settings/accounts';
  static const favourites = '/today/settings/favourites';
  static const rhythm = '/today/settings/rhythm';
  static const recurring = '/today/settings/recurring';
  static const goals = '/today/settings/goals';
  static const events = '/today/settings/events';
  static const backup = '/today/settings/backup';
  static const coachKey = '/today/settings/coach';
  static const runway = '/runway';
  static const insights = '/insights';
  static const coach = '/coach';

  /// One chat with the coach, over the bottom bar.
  static String coachChat(int id) => '/coach/chat/$id';

  /// Above the tabs, so it opens the same way from any of them. Takes
  /// `?period=week|month|all`.
  static const report = '/report';
}
