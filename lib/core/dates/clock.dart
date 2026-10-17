import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wall clock, for anything that measures time passing rather than the
/// day: the lock's time away, the coach's pace. Overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
