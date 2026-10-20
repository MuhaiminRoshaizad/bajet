import 'coach_client.dart';
import 'coach_settings.dart';

/// One chat with the coach: its own messages, name, pin, and the coach and
/// personality it keeps whatever the other chats use.
class CoachThread {
  const CoachThread({
    required this.id,
    required this.title,
    required this.face,
    required this.personality,
    required this.createdAt,
    this.pinned = false,
    this.messages = const [],
  });

  final int id;
  final String title;
  final bool pinned;
  final CoachFace face;
  final CoachPersonality personality;
  final DateTime createdAt;

  /// Oldest first.
  final List<CoachMessage> messages;

  /// When something was last said in it, for ordering the list.
  DateTime get lastAt => messages.lastOrNull?.sentAt ?? createdAt;

  CoachThread copyWith({String? title, bool? pinned, CoachFace? face, CoachPersonality? personality, List<CoachMessage>? messages}) => CoachThread(
        id: id,
        title: title ?? this.title,
        pinned: pinned ?? this.pinned,
        face: face ?? this.face,
        personality: personality ?? this.personality,
        createdAt: createdAt,
        messages: messages ?? this.messages,
      );
}

/// The chat something was said in most recently; null when there are none.
CoachThread? latestThread(List<CoachThread> threads) =>
    threads.isEmpty ? null : threads.reduce((a, b) => b.lastAt.isAfter(a.lastAt) ? b : a);

/// The longest name the user can give a chat.
const chatNameLength = 60;

/// The longest name a chat gets from its first question; past it the
/// question is cut at a word with an ellipsis.
const chatTitleLength = 40;

/// A chat's name from its first question, on one line. The app names it
/// rather than the coach, since asking Anthropic would spend a question.
String chatTitleFrom(String question) {
  final line = question.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (line.length <= chatTitleLength) return line;
  final cut = line.substring(0, chatTitleLength - 1);
  // A cut that already ends a word keeps it; otherwise it goes back to the
  // last space, unless that would leave too little.
  final space = line[cut.length] == ' ' ? cut.length : cut.lastIndexOf(' ');
  return '${(space > chatTitleLength ~/ 2 ? cut.substring(0, space) : cut).trimRight()}…';
}
