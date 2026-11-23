import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_plan_item.dart';
import '../../domain/duonap_today_snapshot.dart';
import '../edit/duonap_sleep_edit_sheet.dart';
import '../edit/duonap_sleep_edit_view_model.dart';
import '../settings/duonap_settings_screen.dart';
import 'duonap_today_state.dart';
import 'duonap_today_view_model.dart';
import 'widgets/duonap_action_bar.dart';
import 'widgets/duonap_night_view.dart';
import 'widgets/duonap_plan_card.dart';
import 'widgets/duonap_today_header.dart';
import 'widgets/duonap_twin_ring.dart';

class DuoNapTodayScreen extends ConsumerWidget {
  const DuoNapTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapTodayViewModelProvider);
    final viewModel = ref.read(duoNapTodayViewModelProvider.notifier);
    final snapshot = state.snapshot;
    if (snapshot != null && state.showNightView) {
      return Scaffold(
        body: DuoNapNightView(
          snapshot: snapshot,
          onBaby: viewModel.onBabyTapped,
          onShowDay: viewModel.showDay,
        ),
      );
    }
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
                : _Today(state: state, snapshot: snapshot, viewModel: viewModel),
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

class _Today extends ConsumerWidget {
  const _Today({required this.state, required this.snapshot, required this.viewModel});

  final DuoNapTodayState state;
  final DuoNapTodaySnapshot snapshot;
  final DuoNapTodayViewModel viewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = state.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DuoNapTodayHeader(
          snapshot: snapshot,
          onSettings: () => _openSettings(context),
          onShowNight: snapshot.isNight ? viewModel.showNight : null,
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DuoNapColors.first),
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
                DuoNapPlanCard(
                  plan: snapshot.plan,
                  secondInitial: snapshot.baby(DuoNapBabyId.second).initial,
                  onRowTap: (item) => _openEdit(context, ref, item),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DuoNapActionBar(
          snapshot: snapshot,
          onBaby: viewModel.onBabyTapped,
          onBoth: (asleep) => viewModel.onBothTapped(asleep: asleep),
        ),
      ],
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref, DuoNapPlanItem item) async {
    final opened = await ref.read(duoNapSleepEditViewModelProvider.notifier).open(item);
    if (!opened || !context.mounted) return;
    await showDuoNapSleepEditSheet(context, snapshot.babies);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DuoNapSettingsScreen()),
    );
  }
}
