import 'dart:convert';
import 'dart:io';

import 'package:bajet/features/coach/data/anthropic_coach_client.dart';
import 'package:bajet/features/coach/data/secure_coach_key_store.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _turns = [CoachMessage(fromOwner: true, text: 'How is my week?')];

Future<String> askWith(MockClient mock) =>
    AnthropicCoachClient(mock).ask(apiKey: 'test-key', system: 'Be brief.', conversation: _turns);

void main() {
  test('sends the key, the version header and the conversation, and reads the text back', () async {
    late http.Request sent;
    final reply = await askWith(MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode({
        'content': [
          {'type': 'text', 'text': 'You are on track.'},
        ],
      }), 200);
    }));
    expect(reply, 'You are on track.');
    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'test-key');
    expect(sent.headers['anthropic-version'], '2023-06-01');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['system'], 'Be brief.');
    expect(body['messages'], [
      {'role': 'user', 'content': 'How is my week?'},
    ]);
  });

  test('turns failures into problems the owner can act on', () async {
    Future<CoachProblem> problem(MockClient mock) async {
      try {
        await askWith(mock);
      } on CoachException catch (e) {
        return e.problem;
      }
      fail('expected a CoachException');
    }

    expect(await problem(MockClient((_) async => http.Response('{}', 401))), CoachProblem.badKey);
    expect(await problem(MockClient((_) async => http.Response('{}', 429))), CoachProblem.busy);
    expect(await problem(MockClient((_) async => http.Response('{}', 500))), CoachProblem.other);
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
