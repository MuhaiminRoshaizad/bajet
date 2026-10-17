import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/coach_client.dart';

/// The coach through Anthropic's Messages API, called with the owner's own
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
    } on SocketException {
      throw const CoachException(CoachProblem.offline);
    } on http.ClientException {
      throw const CoachException(CoachProblem.offline);
    } on TimeoutException {
      throw const CoachException(CoachProblem.busy);
    }
    switch (response.statusCode) {
      case 200:
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
        final stop = body['stop_reason'] as String? ?? 'end_turn';
        // A declined question can come back with no content at all.
        if (stop == 'refusal') throw const CoachException(CoachProblem.refused);
        return CoachTurn(
          stopReason: stop,
          content: [for (final b in (body['content'] as List<Object?>? ?? const [])) if (b is Map) b.cast<String, Object?>()],
        );
      case 401 || 403:
        throw const CoachException(CoachProblem.badKey);
      case 429 || 529 || 503:
        throw const CoachException(CoachProblem.busy);
      default:
        throw const CoachException(CoachProblem.other);
    }
  }
}
