/// A reply texted as a person would: a few short messages in a row, with a
/// pause like typing before each one after the first.
library;

/// What the coach writes, on a line of its own, between two messages.
const burstMark = '<next>';

/// The most messages one reply is sent as; anything past it joins the last.
const burstLimit = 3;

/// [reply] as the messages it is sent as, in order: split at each
/// [burstMark], with empty ones dropped and no more than [burstLimit].
List<String> bursts(String reply) {
  final parts = [for (final p in reply.split(burstMark)) if (p.trim().isNotEmpty) p.trim()];
  if (parts.length <= burstLimit) return parts.isEmpty ? [reply.trim()] : parts;
  return [...parts.take(burstLimit - 1), parts.skip(burstLimit - 1).join('\n\n')];
}

/// Messages in a row as the coach wrote them, for the coach to read back.
String joinBursts(Iterable<String> messages) => messages.join('\n$burstMark\n');

/// How long the coach seems to type [message] before it arrives: longer for
/// longer messages, from half a second to two.
Duration typingPause(String message) => Duration(milliseconds: (400 + message.length * 20).clamp(500, 2000));
