import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_plan_item.dart';
import '../../../domain/duonap_today_snapshot.dart';
import '../duonap_today_formatters.dart';

/// A 24-hour dial with noon at the top. Outer ring is the first baby,
/// inner ring the second. Bright arcs happened, faint arcs are predicted.
class DuoNapTwinRing extends StatelessWidget {
  const DuoNapTwinRing({super.key, required this.snapshot});

  final DuoNapTodaySnapshot snapshot;

  static const double _size = 250;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headline = DuoNapHeadline.of(snapshot);
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _TwinRingPainter(
          first: _arcs(DuoNapBabyId.first),
          second: _arcs(DuoNapBabyId.second),
          now: snapshot.now,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                headline.label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  headline.value,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_RingArc> _arcs(DuoNapBabyId id) {
    final plan = snapshot.babyPlans[id] ?? const <DuoNapPlanItem>[];
    return [for (final item in plan) _arcOf(item)];
  }

  _RingArc _arcOf(DuoNapPlanItem item) {
    final day = DateTime(item.start.year, item.start.month, item.start.day);
    final happened = !item.isPredicted;
    return switch (item.kind) {
      DuoNapPlanKind.wake => _RingArc(day, item.start, happened ? 110 : 55),
      DuoNapPlanKind.nap => _RingArc(item.start, item.end, happened ? 255 : 115),
      DuoNapPlanKind.night => _RingArc(
          item.start,
          day.add(const Duration(days: 1)),
          happened ? 110 : 55,
        ),
    };
  }
}

class _RingArc {
  const _RingArc(this.start, this.end, this.alpha);

  final DateTime start;
  final DateTime end;
  final int alpha;
}

class _RingSpec {
  const _RingSpec(this.center, this.radius, this.color);

  final Offset center;
  final double radius;
  final Color color;
}

class _TwinRingPainter extends CustomPainter {
  _TwinRingPainter({
    required this.first,
    required this.second,
    required this.now,
  });

  final List<_RingArc> first;
  final List<_RingArc> second;
  final DateTime now;

  static const double _stroke = 11;
  static const double _gap = 7;
  static const double _minutesPerDay = 1440;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - _stroke;
    final inner = outer - _stroke - _gap;
    _paintRing(canvas, _RingSpec(center, outer, DuoNapColors.first), first);
    _paintRing(canvas, _RingSpec(center, inner, DuoNapColors.second), second);
    _paintNeedle(canvas, center, outer);
  }

  void _paintRing(Canvas canvas, _RingSpec ring, List<_RingArc> arcs) {
    final rect = Rect.fromCircle(center: ring.center, radius: ring.radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = DuoNapColors.raised;
    canvas.drawCircle(ring.center, ring.radius, track);

    for (final arc in arcs) {
      final minutes = arc.end.difference(arc.start).inMinutes;
      if (minutes <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = ring.color.withAlpha(arc.alpha);
      final sweep = minutes / _minutesPerDay * 2 * math.pi;
      canvas.drawArc(rect, _angle(arc.start), sweep, false, paint);
    }
  }

  void _paintNeedle(Canvas canvas, Offset center, double outer) {
    final angle = _angle(now);
    final direction = Offset(math.cos(angle), math.sin(angle));
    final from = center + direction * (outer - 2 * _stroke - _gap - 6);
    final to = center + direction * (outer + _stroke);
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = DuoNapColors.text;
    canvas.drawLine(from, to, paint);
    canvas.drawCircle(to, 4, Paint()..color = DuoNapColors.text);
  }

  /// Noon points up, 18:00 right, midnight down, 06:00 left.
  double _angle(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    return -math.pi / 2 + (minutes - 720) / _minutesPerDay * 2 * math.pi;
  }

  @override
  bool shouldRepaint(_TwinRingPainter oldDelegate) => true;
}
