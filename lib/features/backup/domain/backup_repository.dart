import '../../accounts/domain/account_models.dart' show firstAccountColor, firstAccountName;

/// The version written into every backup file. Bump it, and add a step to
/// [upgradeBackup], whenever the format changes.
///
/// 1: first release. 2: entries carry `receipt`, an image file name.
/// 3: recurring items carry `windowDays`. 4: planned events carry
/// `repeatsYearly`. 5: entries carry `plannedEventId` and `plannedEventOn`.
/// 6: `accounts` and `transfers`; entries and recurring items carry
/// `accountId`; settings carry the total card's look instead of
/// `openingBalance`, which becomes the first account's. 7: no `brushed`
/// finish; cards that had it are `matte`. 8: `checkins`.
const backupFormatVersion = 8;

/// Brings an older backup up to [backupFormatVersion] one step at a time,
/// so every format ever written still restores. Throws
/// [BackupFormatException] for a format newer than this version knows.
Map<String, Object?> upgradeBackup(Map<String, Object?> backup) {
  var format = backup['format'];
  if (format is! int || format < 1 || format > backupFormatVersion) {
    throw BackupFormatException('This backup uses format $format, which this version of bajet cannot read.');
  }
  var b = backup;
  if (format == 1) {
    b = {
      ...b,
      'format': 2,
      'entries': [for (final e in (b['entries'] as List<Object?>? ?? const [])) {...e! as Map<String, Object?>, 'receipt': null}],
    };
    format = 2;
  }
  if (format == 2) {
    b = {
      ...b,
      'format': 3,
      'recurringItems': [for (final r in (b['recurringItems'] as List<Object?>? ?? const [])) {...r! as Map<String, Object?>, 'windowDays': 0}],
    };
    format = 3;
  }
  if (format == 3) {
    b = {
      ...b,
      'format': 4,
      'plannedEvents': [for (final e in (b['plannedEvents'] as List<Object?>? ?? const [])) {...e! as Map<String, Object?>, 'repeatsYearly': false}],
    };
    format = 4;
  }
  if (format == 4) {
    b = {
      ...b,
      'format': 5,
      'entries': [for (final e in (b['entries'] as List<Object?>? ?? const [])) {...e! as Map<String, Object?>, 'plannedEventId': null, 'plannedEventOn': null}],
    };
    format = 5;
  }
  if (format == 5) {
    // Everything so far was one balance: it becomes one account, which every
    // entry and recurring item belongs to.
    final settings = b['settings'] as Map<String, Object?>?;
    b = {
      ...b,
      'format': 6,
      'settings': settings == null
          ? null
          : ({...settings, 'totalCardColor': null, 'totalCardFinish': 'brushed'}..remove('openingBalance')),
      'accounts': [
        {
          'id': 1,
          'kind': 'bank',
          'name': firstAccountName,
          'nickname': null,
          'openingBalance': settings?['openingBalance'] ?? 0,
          'color': firstAccountColor,
          'inkColor': null,
          'finish': 'brushed',
          'sortOrder': 0,
        },
      ],
      'transfers': const <Object?>[],
      'entries': [for (final e in (b['entries'] as List<Object?>? ?? const [])) {...e! as Map<String, Object?>, 'accountId': 1}],
      'recurringItems': [for (final r in (b['recurringItems'] as List<Object?>? ?? const [])) {...r! as Map<String, Object?>, 'accountId': 1}],
    };
    format = 6;
  }
  if (format == 6) {
    String finish(Object? f) => f == 'brushed' ? 'matte' : f! as String;
    final settings = b['settings'] as Map<String, Object?>?;
    b = {
      ...b,
      'format': 7,
      'settings': settings == null ? null : {...settings, 'totalCardFinish': finish(settings['totalCardFinish'])},
      'accounts': [
        for (final a in (b['accounts'] as List<Object?>? ?? const [])) {...a! as Map<String, Object?>, 'finish': finish((a as Map<String, Object?>)['finish'])},
      ],
    };
    format = 7;
  }
  if (format == 7) {
    b = {...b, 'format': 8, 'checkins': const <Object?>[]};
    format = 8;
  }
  return b;
}

/// Thrown when a file is not a bajet backup this version can read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

abstract interface class BackupRepository {
  /// Everything stored, as plain JSON-ready maps and lists.
  Future<Map<String, Object?>> export();

  /// Replaces everything stored with [backup], in one transaction. Throws
  /// [BackupFormatException], leaving the data untouched, when [backup] is
  /// not a readable bajet backup.
  Future<void> restore(Map<String, Object?> backup);
}
