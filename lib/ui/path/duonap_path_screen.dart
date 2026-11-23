import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_shift.dart';
import '../common/duonap_error_text.dart';
import '../common/duonap_pill_button.dart';
import '../common/duonap_round_button.dart';
import '../common/duonap_sheet_frame.dart';
import 'duonap_path_state.dart';
import 'duonap_path_view_model.dart';
import 'widgets/duonap_path_parts.dart';
import 'widgets/duonap_path_steps.dart';
import 'widgets/duonap_target_sheet.dart';

/// "Rruga drejt 19:00 – 07:00", as in the "D · Rruga 19–07" mockup.
class DuoNapPathScreen extends ConsumerWidget {
  const DuoNapPathScreen({super.key});

  static const double _gap = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapPathViewModelProvider);
    final viewModel = ref.read(duoNapPathViewModelProvider.notifier);
    final error = state.error;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.75),
            radius: 1.0,
            colors: [DuoNapColors.glow, DuoNapColors.ground],
            stops: [0, 0.52],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const _TopBar(),
              const SizedBox(height: 20),
              ..._body(context, state, viewModel),
              if (error != null) DuoNapErrorLine(message: error),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    DuoNapPathState state,
    DuoNapPathViewModel viewModel,
  ) {
    final status = state.status;
    final from = state.startFrom;
    if (state.loading) return const [Center(child: CircularProgressIndicator())];
    if (status == null) {
      if (from == null) return const [];
      return [DuoNapPathStart(from: from, onStart: state.busy ? null : viewModel.start)];
    }
    final now = DateTime.now();
    return [
      DuoNapPathHeadline(status: status),
      const SizedBox(height: _gap),
      DuoNapPathProgress(status: status),
      const SizedBox(height: _gap),
      DuoNapAnchorCards(status: status),
      const SizedBox(height: _gap + 6),
      DuoNapPathSteps(status: status, today: DateTime(now.year, now.month, now.day)),
      const SizedBox(height: _gap),
      DuoNapPathNotes(held: status.held),
      const SizedBox(height: _gap + 6),
      DuoNapPillButton(
        label: 'Ndrysho synimin',
        color: DuoNapColors.raised,
        textColor: DuoNapColors.text,
        height: 56,
        onTap: state.busy ? null : () => _openTarget(context, status, viewModel),
      ),
    ];
  }

  void _openTarget(
    BuildContext context,
    DuoNapShiftStatus status,
    DuoNapPathViewModel viewModel,
  ) {
    final sheet = DuoNapTargetSheet(
      current: status.setup.targetBedtimeMinutes,
      onPick: viewModel.setTarget,
      onStop: viewModel.stop,
    );
    showDuoNapSheet(context, sheet);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DuoNapRoundButton(
          icon: Icons.arrow_back_rounded,
          label: 'Kthehu',
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 14),
        Text(
          'Rruga',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
