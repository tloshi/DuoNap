import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../common/duonap_time_stepper.dart';
import '../../today/duonap_today_formatters.dart';
import '../duonap_sleep_edit_state.dart';

/// The big time range and the line under it: length and date.
class DuoNapEditSummary extends StatelessWidget {
  const DuoNapEditSummary({super.key, required this.state});

  final DuoNapSleepEditState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final start = state.start;
    if (start == null) return const SizedBox.shrink();
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _range(start),
            style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _detail(start),
          style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
        ),
      ],
    );
  }

  String _range(DateTime start) {
    if (state.isWake) return DuoNapFormat.clock(start);
    final end = state.end;
    final to = end == null ? 'po fle' : DuoNapFormat.clock(end);
    return '${DuoNapFormat.clock(start)} – $to';
  }

  String _detail(DateTime start) {
    final end = state.end;
    final date = DuoNapFormat.date(start);
    if (state.isWake || end == null) return date;
    return '${DuoNapFormat.duration(end.difference(start))}, $date';
  }
}

/// Start and end steppers, or one wake-up stepper. One minute per tap.
class DuoNapEditTimes extends StatelessWidget {
  const DuoNapEditTimes({
    super.key,
    required this.state,
    required this.onStart,
    required this.onEnd,
  });

  final DuoNapSleepEditState state;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;

  @override
  Widget build(BuildContext context) {
    final start = state.start;
    if (start == null) return const SizedBox.shrink();
    if (state.isWake) {
      return _stepper('U zgjua në', start, onStart);
    }
    final end = state.end;
    return Row(
      children: [
        Expanded(child: _stepper('Fillimi', start, onStart)),
        const SizedBox(width: 10),
        Expanded(
          child: end == null ? const _StillAsleep() : _stepper('Fundi', end, onEnd),
        ),
      ],
    );
  }

  Widget _stepper(String label, DateTime value, ValueChanged<int> onNudge) {
    return DuoNapTimeStepper(
      label: label,
      value: DuoNapFormat.clock(value),
      onMinus: () => onNudge(-1),
      onPlus: () => onNudge(1),
      minusLabel: '$label një minutë më herët',
      plusLabel: '$label një minutë më vonë',
    );
  }
}

class _StillAsleep extends StatelessWidget {
  const _StillAsleep();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DuoNapColors.inset,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Fundi: po fle',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
      ),
    );
  }
}
