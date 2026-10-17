import 'dart:convert';
import 'dart:io';

import 'package:bajet/features/coach/data/anthropic_coach_client.dart';
import 'package:bajet/features/coach/data/secure_coach_key_store.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _request = CoachRequest(
  model: 'claude-sonnet-5-5',
  system: 'Be brief.',
  messages: [
    {'role': 'user', 'content': 'How is my week?'},
  ],
  tools: [
    {'name': 'bajet_accounts', 'description': 'Accounts.', 'input_schema': {'type': 'object', 'properties': {}}},
  ],
);

Future<CoachTurn> sendWith(MockClient mock, [CoachRequest request = _request]) => AnthropicCoachClient(mock).send(apiKey: 'test-key', request: request);

http.Response reply(Map<String, Object?> body) => http.Response(jsonEncode(body), 200);

void main() {
  test('sends the key, the version, the tools and a low effort, with fallback on for Sonnet', () async {
    late http.Request sent;
    final turn = await sendWith(MockClient((request) async {
      sent = request;
      return reply({
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': ''},
          {'type': 'text', 'text': 'You are on track.'},
        ],
      });
    }));
    expect(turn.text, 'You are on track.');
    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'test-key');
    expect(sent.headers['anthropic-version'], '2023-06-01');
    expect(sent.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['system'], 'Be brief.');
    expect(body['messages'], _request.messages);
    expect((body['tools'] as List).single, containsPair('name', 'bajet_accounts'));
    expect(body['output_config'], {'effort': 'low'});
    expect(body['fallbacks'], 'default');
    expect(body.containsKey('tool_choice'), isFalse);
  });

  test('reads a lookup request, and can tell the model to stop looking things up', () async {
    late Map<String, Object?> body;
    final turn = await sendWith(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, Object?>;
        return reply({
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'tool_use', 'id': 'toolu_1', 'name': 'bajet_accounts', 'input': {}},
          ],
        });
      }),
      CoachRequest(model: 'claude-sonnet-5-5', system: 'Be brief.', messages: _request.messages, tools: _request.tools, noMoreTools: true),
    );
    expect(turn.calls.single.$2, 'bajet_accounts');
    expect(body['tool_choice'], {'type': 'none'});
  });

  test('a classifier asks for JSON with thinking off, and gets no fallback', () async {
    late http.Request sent;
    await sendWith(
      MockClient((request) async {
        sent = request;
        return reply({'stop_reason': 'end_turn', 'content': [{'type': 'text', 'text': '{"kind":"money"}'}]});
      }),
      const CoachRequest(model: 'claude-haiku-5-5', system: 'Sort it.', messages: [{'role': 'user', 'content': 'hi'}], thinkingOff: true, outputSchema: {'type': 'object'}),
    );
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['thinking'], {'type': 'disabled'});
    expect(body['output_config'], {'effort': 'low', 'format': {'type': 'json_schema', 'schema': {'type': 'object'}}});
    expect(sent.headers.containsKey('anthropic-beta'), isFalse);
    expect(body.containsKey('fallbacks'), isFalse);
  });

  test('turns failures into problems the owner can act on', () async {
    Future<CoachProblem> problem(MockClient mock) async {
      try {
        await sendWith(mock);
      } on CoachException catch (e) {
        return e.problem;
      }
      fail('expected a CoachException');
    }

    expect(await problem(MockClient((_) async => http.Response('{}', 401))), CoachProblem.badKey);
    expect(await problem(MockClient((_) async => http.Response('{}', 429))), CoachProblem.busy);
    expect(await problem(MockClient((_) async => http.Response('{}', 500))), CoachProblem.other);
    expect(await problem(MockClient((_) async => reply({'stop_reason': 'refusal', 'content': []}))), CoachProblem.refused);
    expect(await problem(MockClient((_) async => throw const SocketException('no route'))), CoachProblem.offline);
  });

  test('the key and the day count live in secure storage, and the count resets each day', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const store = SecureCoachKeyStore();
    final monday = DateTime.utc(2026, 7, 6);
    await store.saveKey('  test-key  ');
    expect(await store.readKey(), 'test-key');

    await store.recordUse(monday);
    await store.recordUse(monday);
    expect(await store.usedOn(monday), 2);
    expect(await store.usedOn(DateTime.utc(2026, 7, 7)), 0);

    await store.deleteKey();
    expect(await store.readKey(), isNull);
  });
}
