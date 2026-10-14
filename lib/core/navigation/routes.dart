/// Route paths, kept apart from the router so features can link to one
/// another without importing the app layer that builds them.
abstract final class Routes {
  static const loading = '/loading';
  static const setup = '/setup';
  static const today = '/today';
  static const runway = '/runway';
  static const insights = '/insights';
  static const coach = '/coach';
}
