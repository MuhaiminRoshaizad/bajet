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

  /// Capable enough to reason about a budget, and kinder to a personal key
  /// than the largest model.
  static const model = 'claude-sonnet-5-5';

  @override
  Future<String> ask({required String apiKey, required String system, required List<CoachMessage> conversation}) async {
    final http.Response response;
    try {
      response = await _http
          .post(
            _endpoint,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 700,
              'system': system,
              'messages': [
                for (final m in conversation) {'role': m.fromOwner ? 'user' : 'assistant', 'content': m.text},
              ],
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
        final text = [
          for (final block in (body['content'] as List<Object?>? ?? const []))
            if (block is Map && block['type'] == 'text') block['text'] as String,
        ].join('\n').trim();
        if (text.isEmpty) throw const CoachException(CoachProblem.other);
        return text;
      case 401 || 403:
        throw const CoachException(CoachProblem.badKey);
      case 429 || 529 || 503:
        throw const CoachException(CoachProblem.busy);
      default:
        throw const CoachException(CoachProblem.other);
    }
  }
}
