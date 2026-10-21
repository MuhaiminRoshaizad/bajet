import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart source under lib/, except generated code.
Iterable<(String, String)> sources() sync* {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')) yield (f.path, f.readAsStringSync());
  }
}

void main() {
  test('no field opens the keyboard by itself', () {
    expect([for (final (path, text) in sources()) if (text.contains('autofocus: true')) path], isEmpty);
  });

  test("every TextField stays out of the phone's autofill", () {
    final missing = [
      for (final (path, text) in sources())
        if (RegExp(r'(?<!Form)TextField\(\r?\n').allMatches(text).length != 'autofillHints: null'.allMatches(text).length) path,
    ];
    expect(missing, isEmpty);
  });
}
