/// The longest name a chat gets from its first question; past it the
/// question is cut at a word with an ellipsis.
const chatTitleLength = 40;

/// A chat's name from its first question, on one line. The app names it
/// rather than the coach, since asking Anthropic would spend a question.
String chatTitleFrom(String question) {
  final line = question.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (line.length <= chatTitleLength) return line;
  final cut = line.substring(0, chatTitleLength - 1);
  final space = cut.lastIndexOf(' ');
  return '${(space > chatTitleLength ~/ 2 ? cut.substring(0, space) : cut).trimRight()}…';
}
