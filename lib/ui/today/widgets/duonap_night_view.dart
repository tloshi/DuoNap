import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_today_snapshot.dart';
import '../../common/duonap_pill_button.dart';
import '../duonap_today_formatters.dart';

/// Dim screen for the night: the time, the morning wake-up, and one large
/// button per baby for night wake-ups. Layout from the "Nata" mockup.
class DuoNapNightView extends StatelessWidget {
  const DuoNapNightView({
    super.key,
    required this.snapshot,
    required this.onBaby,
    required this.onShowDay,
  });

  final DuoNapTodaySnapshot snapshot;
  final ValueChanged<DuoNapBabyId> onBaby;
  final VoidCallback onShowDay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: DuoNapColors.muted);
    return ColoredBox(
      color: DuoNapColors.night,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Natë', textAlign: TextAlign.center, style: muted),
              Text(
                DuoNapFormat.clock(snapshot.now),
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(
                  color: DuoNapColors.soft,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(_wakeLine(), textAlign: TextAlign.center, style: muted),
              const SizedBox(height: 24),
              for (final baby in snapshot.babies) ...[
                _BabyCard(
                  baby: baby,
                  status: snapshot.statuses[baby.id],
                  onTap: () => onBaby(baby.id),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              _DayLink(onTap: onShowDay),
            ],
          ),
        ),
      ),
    );
  }

  String _wakeLine() {
    final wake = snapshot.nextWake;
    final wait = DuoNapFormat.duration(wake.difference(snapshot.now));
    return 'Zgjimi i mëngjesit ${DuoNapFormat.clock(wake)}, edhe $wait';
  }
}

class _BabyCard extends StatelessWidget {
  const _BabyCard({required this.baby, required this.status, required this.onTap});

  final DuoNapBaby baby;
  final DuoNapBabyStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final asleep = status?.asleep ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Initial(baby: baby),
              const SizedBox(width: 10),
              Text(baby.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(_statusLine(), style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          DuoNapPillButton(
            label: asleep ? 'U zgjua' : 'Fjeti',
            color: asleep ? DuoNapColors.raised : DuoNapColors.soft,
            textColor: asleep ? DuoNapColors.soft : DuoNapColors.ground,
            height: 64,
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  String _statusLine() {
    final since = status?.since;
    final asleep = status?.asleep ?? false;
    if (since == null) return asleep ? 'Po fle' : 'Zgjuar';
    final time = DuoNapFormat.clock(since);
    return asleep ? 'Po fle prej $time' : 'Zgjuar prej $time';
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.baby});

  final DuoNapBaby baby;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: DuoNapColors.ofBaby(baby.id), shape: BoxShape.circle),
      child: Text(
        baby.initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DuoNapColors.ground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DayLink extends StatelessWidget {
  const _DayLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 18, color: DuoNapColors.muted),
              const SizedBox(width: 8),
              Text(
                'Pamja e ditës',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: DuoNapColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
