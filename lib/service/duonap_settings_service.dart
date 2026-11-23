import '../core/duonap_result.dart';
import '../data/duonap_settings_repository.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_settings.dart';
import 'duonap_day_history.dart';

/// Loads and saves the family settings and keeps them inside the day rules:
/// the usual wake-up falls in the morning window, bedtime in the evening.
class DuoNapSettingsService {
  DuoNapSettingsService({required DuoNapSettingsRepository repository})
      : _repository = repository;

  static const int _minutesPerHour = 60;
  static const int _midnight = 24 * _minutesPerHour;

  final DuoNapSettingsRepository _repository;

  Future<DuoNapResult<DuoNapSettings>> load() => _repository.load();

  Future<DuoNapResult<void>> save(DuoNapSettings settings) async {
    final cleaned = settings
        .withName(DuoNapBabyId.first, settings.firstName.trim())
        .withName(DuoNapBabyId.second, settings.secondName.trim());
    final problem = _problemWith(cleaned);
    if (problem != null) return problem;
    return _repository.save(cleaned);
  }

  DuoNapFailure<void>? _problemWith(DuoNapSettings settings) {
    final names = [settings.firstName, settings.secondName];
    if (names.any((name) => name.isEmpty)) {
      return const DuoNapFailure<void>('NAME_EMPTY', 'A name is empty.');
    }
    if (names.any((name) => name.length > DuoNapSettings.maxNameLength)) {
      return const DuoNapFailure<void>('NAME_TOO_LONG', 'A name is too long.');
    }
    if (!_isMorning(settings.usualWakeMinutes)) {
      return const DuoNapFailure<void>('WAKE_OUT_OF_RANGE', 'Wake time is not in the morning.');
    }
    if (!_isEvening(settings.plannedBedtimeMinutes)) {
      return const DuoNapFailure<void>('BEDTIME_OUT_OF_RANGE', 'Bedtime is not in the evening.');
    }
    return null;
  }

  bool _isMorning(int minutes) {
    const from = DuoNapDayHistory.earliestWakeHour * _minutesPerHour;
    const to = DuoNapDayHistory.latestWakeHour * _minutesPerHour;
    return minutes >= from && minutes < to;
  }

  bool _isEvening(int minutes) {
    const from = DuoNapDayHistory.latestWakeHour * _minutesPerHour;
    return minutes >= from && minutes < _midnight;
  }
}
