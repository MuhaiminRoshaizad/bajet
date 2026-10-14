import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/dates/dates.dart';
import '../domain/coach_client.dart';

/// The key in the platform's secure storage (Android Keystore, iOS
/// Keychain), never in the database, a backup file or the code. Android
/// Auto Backup leaves it out (res/xml/backup_rules.xml), so a restored phone
/// asks for the key again rather than holding one it cannot decrypt.
class SecureCoachKeyStore implements CoachKeyStore {
  const SecureCoachKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _key = 'anthropic_api_key';
  static const _usage = 'coach_usage';

  @override
  Future<String?> readKey() => _storage.read(key: _key);

  @override
  Future<void> saveKey(String key) => _storage.write(key: _key, value: key.trim());

  @override
  Future<void> deleteKey() => _storage.delete(key: _key);

  // Stored as "dd/mm/yyyy:count" beside the key, so the limit needs no
  // other storage and resets itself on a new day.
  @override
  Future<int> usedOn(DateTime day) async {
    final raw = await _storage.read(key: _usage);
    final parts = raw?.split(':');
    if (parts == null || parts.length != 2 || parts[0] != Dates.full(day)) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  @override
  Future<void> recordUse(DateTime day) async => _storage.write(key: _usage, value: '${Dates.full(day)}:${await usedOn(day) + 1}');
}
