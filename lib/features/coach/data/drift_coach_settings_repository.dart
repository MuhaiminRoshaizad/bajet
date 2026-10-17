import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/coach_settings.dart' as domain;

class DriftCoachSettingsRepository implements domain.CoachSettingsRepository {
  DriftCoachSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<domain.CoachSettings> watchSettings() => _db.select(_db.coachSettings).watchSingleOrNull().map(
        (r) => r == null
            ? const domain.CoachSettings()
            : domain.CoachSettings(
                // A key from a newer version this one does not know falls back
                // to the default rather than failing.
                face: domain.CoachFace.values.asNameMap()[r.face] ?? domain.CoachFace.bajety,
                personality: domain.CoachPersonality.values.asNameMap()[r.personality] ?? domain.CoachPersonality.friendly,
                remember: r.remember,
              ),
      );

  @override
  Future<void> saveSettings(domain.CoachSettings s) => _db.into(_db.coachSettings).insertOnConflictUpdate(
        CoachSettingsCompanion.insert(id: const Value(1), face: Value(s.face.name), personality: Value(s.personality.name), remember: Value(s.remember)),
      );
}
