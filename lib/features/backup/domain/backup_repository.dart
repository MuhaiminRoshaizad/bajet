/// The version written into every backup file. Bump it, and teach
/// [BackupRepository.restore] to read the old one, whenever the format changes.
const backupFormatVersion = 1;

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
