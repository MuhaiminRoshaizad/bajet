import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/drift_checkin_repository.dart';
import '../domain/checkin.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) => DriftCheckinRepository(ref.watch(databaseProvider)));

/// Every finished check-in, newest first.
final checkinsProvider = StreamProvider<List<Checkin>>((ref) => ref.watch(checkinRepositoryProvider).watchCheckins());
