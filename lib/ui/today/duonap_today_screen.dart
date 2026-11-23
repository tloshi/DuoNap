import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_today_snapshot.dart';
import 'duonap_today_formatters.dart';
import 'duonap_today_state.dart';
import 'duonap_today_view_model.dart';
import 'widgets/duonap_action_bar.dart';
import 'widgets/duonap_plan_card.dart';
import 'widgets/duonap_twin_ring.dart';

class DuoNapTodayScreen extends ConsumerWidget {
  const DuoNapTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapTodayViewModelProvider);
    final viewModel = ref.read(duoNapTodayViewModelProvider.notifier);
    final snapshot = state.snapshot;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.1,
            colors: [DuoNapColors.glow, DuoNapColors.ground],
            stops: [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: snapshot == null
                ? _Waiting(state: state)
                : _Today(
                    snapshot: snapshot,
                    error: state.error,
                    onBaby: viewModel.onBabyTapped,
                    onBoth: (asleep) => viewModel.onBothTapped(asleep: asleep),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.state});

  final DuoNapTodayState state;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    return Center(
      child: error == null
          ? const CircularProgressIndicator()
          : Text(error, textAlign: TextAlign.center),
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({
    required this.snapshot,
    required this.error,
    required this.onBaby,
    required this.onBoth,
  });

  final DuoNapTodaySnapshot snapshot;
  final String? error;
  final ValueChanged<DuoNapBabyId> onBaby;
  final ValueChanged<bool> onBoth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _TwinAvatars(),
            Text(
              'Sot, ora ${DuoNapFormat.clock(snapshot.now)}',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 64),
          ],
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: DuoNapColors.first),
            ),
          ),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: DuoNapTwinRing(snapshot: snapshot)),
                const SizedBox(height: 14),
                DuoNapPlanCard(plan: snapshot.plan),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DuoNapActionBar(snapshot: snapshot, onBaby: onBaby, onBoth: onBoth),
      ],
    );
  }
}

class _TwinAvatars extends StatelessWidget {
  const _TwinAvatars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Stack(
        children: [
          for (final baby in DuoNapFamily.babies)
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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
