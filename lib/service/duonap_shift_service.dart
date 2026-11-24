import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../data/duonap_settings_repository.dart';
import '../data/duonap_shift_repository.dart';
import '../data/duonap_sleep_repository.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_shift_plan.dart';

/// Starts, stops and reports the path toward 19:00 – 07:00.
class DuoNapShiftService {
  DuoNapShiftService({
    required DuoNapShiftRepository shift,
    required DuoNapSettingsRepository settings,
    required DuoNapSleepRepository sleep,
    DuoNapClock? clock,
  })  : _shift = shift,
        _settings = settings,
        _sleep = sleep,
        _clock = clock ?? DateTime.now;

  static const DuoNapFailure<void> _notRunning =
      DuoNapFailure<void>('NOT_RUNNING', 'No path has been started.');

  final DuoNapShiftRepository _shift;
  final DuoNapSettingsRepository _settings;
  final DuoNapSleepRepository _sleep;
  final DuoNapClock _clock;

  /// Where the path stands today, or null when none is running.
  Future<DuoNapResult<DuoNapShiftStatus?>> status() async {
    final loaded = await _shift.load();
    if (loaded is! DuoNapSuccess<DuoNapShiftSetup?>) {
      return const DuoNapFailure<DuoNapShiftStatus?>('LOAD_FAILED', 'Could not read the path.');
    }
    final setup = loaded.data;
    if (setup == null) return const DuoNapSuccess<DuoNapShiftStatus?>(null);
    final from = setup.startDay.subtract(const Duration(days: 1));
    final sessions = await _sleep.loadSince(from);
    return sessions.fold<DuoNapResult<DuoNapShiftStatus?>>(
      (failure) => DuoNapFailure<DuoNapShiftStatus?>(failure.code, failure.message),
      (List<DuoNapSleepSession> log) => DuoNapSuccess<DuoNapShiftStatus?>(
        DuoNapShiftPlan.fromLog(setup, log).statusOn(_today()),
      ),
    );
  }

  /// Whether a path is running, without reading the sleep log.
  Future<DuoNapResult<bool>> isRunning() async {
    final loaded = await _shift.load();
    return loaded.fold<DuoNapResult<bool>>(
      (failure) => DuoNapFailure<bool>(failure.code, failure.message),
      (DuoNapShiftSetup? setup) => DuoNapSuccess<bool>(setup != null),
    );
  }

  /// Starts today from the wake-up and bedtime in settings, aiming at 19:30.
  Future<DuoNapResult<void>> start() async {
    final current = await _shift.load();
    if (current is DuoNapSuccess<DuoNapShiftSetup?> && current.data != null) {
      return const DuoNapFailure<void>('ALREADY_RUNNING', 'A path is already running.');
    }
    final settings = await _settings.load();
    if (settings is! DuoNapSuccess<DuoNapSettings>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read settings.');
    }
    return _shift.save(
      DuoNapShiftSetup(
        startDay: _today(),
        start: settings.data.anchors,
        targetBedtimeMinutes: DuoNapShiftSetup.defaultTargetBedtimeMinutes,
      ),
    );
  }

  Future<DuoNapResult<void>> stop() => _shift.clear();

  /// [minutes] must be one of [DuoNapShiftSetup.targetChoices].
  Future<DuoNapResult<void>> setTarget(int minutes) async {
    if (!DuoNapShiftSetup.targetChoices.contains(minutes)) {
      return const DuoNapFailure<void>('TARGET_INVALID', 'Not a target choice.');
    }
    final current = await _shift.load();
    if (current is! DuoNapSuccess<DuoNapShiftSetup?>) return _notRunning;
    final setup = current.data;
    if (setup == null) return _notRunning;
    return _shift.save(setup.withTarget(minutes));
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
