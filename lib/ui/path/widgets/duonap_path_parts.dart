import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_anchors.dart';
import '../../../domain/duonap_shift.dart';
import '../../common/duonap_pill_button.dart';
import '../../today/duonap_today_formatters.dart';

String _clock(int minutes) => DuoNapFormat.minutesOfDay(minutes);

/// "Rruga drejt", the target, and how far along the path is.
class DuoNapPathHeadline extends StatelessWidget {
  const DuoNapPathHeadline({super.key, required this.status});

  final DuoNapShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = status.setup.targetBedtimeMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rruga drejt', style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted)),
        Text(
          '${_clock(target)} – ${_clock(DuoNapShiftSetup.targetWakeMinutes)}',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(_progressLine(), style: textTheme.bodySmall?.copyWith(color: DuoNapColors.soft)),
      ],
    );
  }

  String _progressLine() {
    final arrival = status.arrival;
    if (status.finished || arrival == null) return 'Synimi u arrit.';
    final step = 'Hapi ${status.stepsDone} nga ${status.stepsTotal}';
    return '$step, mbërritja rreth ${DuoNapFormat.arrival(arrival)}';
  }
}

/// One segment per step: bright when done, the latest one glowing.
class DuoNapPathProgress extends StatelessWidget {
  const DuoNapPathProgress({super.key, required this.status});

  final DuoNapShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final done = status.stepsDone;
    return Semantics(
      label: 'Përparimi: $done nga ${status.stepsTotal} hapa',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var step = 1; step <= status.stepsTotal; step++) ...[
            if (step > 1) const SizedBox(width: 4),
            Expanded(child: _segment(step <= done, step == done)),
          ],
        ],
      ),
    );
  }

  Widget _segment(bool isDone, bool isLatest) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDone ? DuoNapColors.text : DuoNapColors.highlight,
        borderRadius: BorderRadius.circular(3),
        boxShadow: isLatest
            ? const [BoxShadow(color: Color(0x99F4F2FF), blurRadius: 10)]
            : null,
      ),
    );
  }
}

/// "Zgjimi sot" and "Nata sonte", each with where it started and where it goes.
class DuoNapAnchorCards extends StatelessWidget {
  const DuoNapAnchorCards({super.key, required this.status});

  final DuoNapShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final start = status.setup.start;
    return Row(
      children: [
        Expanded(
          child: _AnchorCard(
            label: 'Zgjimi sot',
            minutes: status.today.wakeMinutes,
            route: 'prej ${_clock(start.wakeMinutes)} drejt ${_clock(DuoNapShiftSetup.targetWakeMinutes)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnchorCard(
            label: 'Nata sonte',
            minutes: status.today.bedtimeMinutes,
            route: 'prej ${_clock(start.bedtimeMinutes)} drejt ${_clock(status.setup.targetBedtimeMinutes)}',
          ),
        ),
      ],
    );
  }
}

class _AnchorCard extends StatelessWidget {
  const _AnchorCard({required this.label, required this.minutes, required this.route});

  final String label;
  final int minutes;
  final String route;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelSmall?.copyWith(color: DuoNapColors.muted);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: muted?.copyWith(fontWeight: FontWeight.w600)),
          Text(_clock(minutes), style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(route, style: muted),
        ],
      ),
    );
  }
}

/// Shown before the path is started: what it does and where it starts from.
class DuoNapPathStart extends StatelessWidget {
  const DuoNapPathStart({super.key, required this.from, required this.onStart});

  final DuoNapAnchors from;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyMedium?.copyWith(color: DuoNapColors.soft, height: 1.4);
    final target = _clock(DuoNapShiftSetup.defaultTargetBedtimeMinutes);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rruga drejt 19:00 – 07:00', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'Çdo tri ditë zgjimi dhe nata lëvizin 15 minuta më herët. Zgjimi ndalet '
            'te 07:00, nata te synimi.',
            style: body,
          ),
          const SizedBox(height: 10),
          Text(
            'Nis sot nga orët në Cilësimet: zgjimi ${_clock(from.wakeMinutes)}, '
            'nata ${_clock(from.bedtimeMinutes)}. Synimi: $target.',
            style: body,
          ),
          const SizedBox(height: 20),
          DuoNapPillButton(label: 'Fillo rrugën', color: DuoNapColors.text, height: 56, onTap: onStart),
        ],
      ),
    );
  }
}
