import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_today_snapshot.dart';
import '../../common/duonap_round_button.dart';
import '../duonap_today_formatters.dart';

/// Twin avatars, the time, and the buttons for the night view, the path
/// toward 19:00 – 07:00, and settings.
class DuoNapTodayHeader extends StatelessWidget {
  const DuoNapTodayHeader({
    super.key,
    required this.snapshot,
    required this.onPath,
    required this.onSettings,
    this.onShowNight,
  });

  final DuoNapTodaySnapshot snapshot;
  final VoidCallback onPath;
  final VoidCallback onSettings;

  /// Set only at night, when the parent chose the day view instead.
  final VoidCallback? onShowNight;

  @override
  Widget build(BuildContext context) {
    final showNight = onShowNight;
    return Row(
      children: [
        _TwinAvatars(babies: snapshot.babies),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Sot, ora ${DuoNapFormat.clock(snapshot.now)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (showNight != null) ...[
          DuoNapRoundButton(
            icon: Icons.bedtime_outlined,
            label: 'Pamja e natës',
            onTap: showNight,
          ),
          const SizedBox(width: 8),
        ],
        DuoNapRoundButton(
          icon: Icons.trending_down_rounded,
          label: 'Rruga drejt 19 deri 07',
          onTap: onPath,
        ),
        const SizedBox(width: 8),
        DuoNapRoundButton(
          icon: Icons.tune_rounded,
          label: 'Cilësimet',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _TwinAvatars extends StatelessWidget {
  const _TwinAvatars({required this.babies});

  final List<DuoNapBaby> babies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Stack(
        children: [
          for (final baby in babies)
            Positioned(
              left: baby.id == DuoNapBabyId.first ? 0 : 28,
              child: _Avatar(baby: baby),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.baby});

  final DuoNapBaby baby;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: DuoNapColors.ofBaby(baby.id), width: 2),
      ),
      child: Text(
        baby.initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
