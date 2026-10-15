/// The version written into every backup file. Bump it, and add a step to
/// [upgradeBackup], whenever the format changes.
///
/// 1: first release. 2: entries carry `receipt`, an image file name.
/// 3: recurring items carry `windowDays`.
const backupFormatVersion = 3;

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
