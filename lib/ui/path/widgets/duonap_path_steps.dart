import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_anchors.dart';
import '../../../domain/duonap_shift.dart';
import '../../today/duonap_today_formatters.dart';

/// "Hapat e ardhshëm": today, the next few steps and the last one, on a line.
class DuoNapPathSteps extends StatelessWidget {
  const DuoNapPathSteps({super.key, required this.status, required this.today});

  static const int _shown = 4;

  final DuoNapShiftStatus status;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final upcoming = status.upcoming;
    final next = upcoming.take(_shown).toList();
    final last = upcoming.length > _shown ? upcoming.last : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        const SizedBox(height: 6),
        Stack(
          children: [
            const Positioned(left: 11, top: 20, bottom: 20, child: _Line()),
            Column(
              children: [
                _StepRow(day: today, today: today, anchors: status.today, kind: _Dot.now),
                for (final step in next)
                  _StepRow(day: step.day, today: today, anchors: step.anchors, kind: _Dot.next),
                if (last != null)
                  _StepRow(day: last.day, today: today, anchors: last.anchors, kind: _Dot.goal),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

enum _Dot { now, next, goal }

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DuoNapColors.muted,
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: [
        const SizedBox(width: 32),
        Expanded(child: Text('Hapat e ardhshëm', style: style)),
        SizedBox(width: 64, child: Text('Zgjimi', textAlign: TextAlign.right, style: style)),
        SizedBox(width: 64, child: Text('Nata', textAlign: TextAlign.right, style: style)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 2, child: ColoredBox(color: DuoNapColors.sheetBorder));
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.day,
    required this.today,
    required this.anchors,
    required this.kind,
  });

  final DateTime day;
  final DateTime today;
  final DuoNapAnchors anchors;
  final _Dot kind;

  @override
  Widget build(BuildContext context) {
    final strong = kind != _Dot.next;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
          color: strong ? DuoNapColors.text : DuoNapColors.soft,
        );
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: _dot())),
          const SizedBox(width: 8),
          Expanded(child: Text(DuoNapFormat.stepDay(day, today), style: style)),
          SizedBox(width: 64, child: Text(_clock(anchors.wakeMinutes), textAlign: TextAlign.right, style: style)),
          SizedBox(width: 64, child: Text(_clock(anchors.bedtimeMinutes), textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }

  String _clock(int minutes) => DuoNapFormat.minutesOfDay(minutes);

  Widget _dot() {
    return switch (kind) {
      _Dot.now => Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: DuoNapColors.text,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0xB3F4F2FF), blurRadius: 12)],
          ),
        ),
      _Dot.next => _ring(10, 2, DuoNapColors.outline),
      _Dot.goal => _ring(14, 3, DuoNapColors.text),
    };
  }

  Widget _ring(double size, double width, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DuoNapColors.ground,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    );
  }
}
