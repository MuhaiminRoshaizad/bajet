import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/coach_client.dart';

/// The coach through Anthropic's Messages API, called with the user's own
/// key straight from the phone; there is no bajet server in between.
class AnthropicCoachClient implements CoachClient {
  AnthropicCoachClient([http.Client? client]) : _http = client ?? http.Client();

  final http.Client _http;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  Future<CoachTurn> send({required String apiKey, required CoachRequest request}) async {
    // Sonnet 5.5 can retry a declined question on another model itself; the
    // other models take the refusal as final.
    final fallback = request.model.startsWith('claude-sonnet');
    final http.Response response;
    try {
      response = await _http
          .post(
            _endpoint,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              if (fallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': request.model,
              'max_tokens': request.maxTokens,
              'system': request.system,
              'messages': request.messages,
              if (request.tools.isNotEmpty) 'tools': request.tools,
              if (request.tools.isNotEmpty && request.noMoreTools) 'tool_choice': {'type': 'none'},
              if (request.thinkingOff) 'thinking': {'type': 'disabled'},
              'output_config': {
                'effort': request.effort,
                if (request.outputSchema != null) 'format': {'type': 'json_schema', 'schema': request.outputSchema},
              },
              if (fallback) 'fallbacks': 'default',
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on IOException {
      // Sockets, and the secure handshake a wifi sign-in page breaks, which
      // package:http passes through unwrapped.
      throw const CoachException(CoachProblem.offline);
    } on http.ClientException {
      throw const CoachException(CoachProblem.offline);
    } on TimeoutException {
      throw const CoachException(CoachProblem.busy);
    }
    switch (response.statusCode) {
      case 200:
        final (stop, content) = _read(response);
        // A declined question can come back with no content at all.
        if (stop == 'refusal') throw const CoachException(CoachProblem.refused);
        return CoachTurn(stopReason: stop, content: content);
      case 401 || 403:
        throw const CoachException(CoachProblem.badKey);
      case 429 || 529 || 503:
        throw const CoachException(CoachProblem.busy);
      default:
        throw const CoachException(CoachProblem.other);
    }
  }

  /// The stop reason and content blocks of a 200 reply. Anything that is not
  /// the API's JSON, such as a wifi sign-in page, is a problem to report
  /// rather than a crash.
  static (String, List<Map<String, Object?>>) _read(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const CoachException(CoachProblem.other);
    }
    return switch (body) {
      {'content': final List<Object?> content} => (
          body['stop_reason'] as String? ?? 'end_turn',
          [for (final b in content) if (b is Map<String, Object?>) b],
        ),
      // A refusal may carry no content at all.
      {'stop_reason': 'refusal'} => ('refusal', const []),
      _ => throw const CoachException(CoachProblem.other),
    };
  }
}
