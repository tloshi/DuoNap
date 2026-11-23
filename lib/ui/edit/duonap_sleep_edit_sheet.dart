import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_plan_item.dart';
import '../common/duonap_error_text.dart';
import '../common/duonap_pill_button.dart';
import '../common/duonap_round_button.dart';
import '../common/duonap_sheet_frame.dart';
import 'duonap_sleep_edit_state.dart';
import 'duonap_sleep_edit_view_model.dart';
import 'widgets/duonap_sleep_edit_parts.dart';
import 'widgets/duonap_target_selector.dart';

/// Opens the sheet for whatever the edit view model has loaded.
Future<void> showDuoNapSleepEditSheet(
  BuildContext context,
  List<DuoNapBaby> babies,
) {
  return showDuoNapSheet(context, DuoNapSleepEditSheet(babies: babies));
}

/// Bottom sheet to correct a logged sleep or log the morning wake-up,
/// following the "D · Dialogu" mockup.
class DuoNapSleepEditSheet extends ConsumerWidget {
  const DuoNapSleepEditSheet({super.key, required this.babies});

  final List<DuoNapBaby> babies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapSleepEditViewModelProvider);
    final viewModel = ref.read(duoNapSleepEditViewModelProvider.notifier);
    final error = state.error;
    return DuoNapSheetFrame(
      title: _title(state),
      children: [
        DuoNapTargetSelector(
          babies: babies,
          selected: state.target,
          available: state.targets,
          onSelect: viewModel.select,
        ),
        DuoNapEditSummary(state: state),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DuoNapEditTimes(
              state: state,
              onStart: viewModel.nudgeStart,
              onEnd: viewModel.nudgeEnd,
            ),
            if (error != null) DuoNapErrorLine(message: error),
          ],
        ),
        _Actions(state: state, onSave: viewModel.save, onDelete: viewModel.delete),
      ],
    );
  }

  String _title(DuoNapSleepEditState state) {
    return switch (state.logged?.item.kind) {
      DuoNapPlanKind.wake => 'Zgjimi i mëngjesit',
      DuoNapPlanKind.night => 'Gjumi i natës',
      _ => 'Gjumë ditor',
    };
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.onSave, required this.onDelete});

  final DuoNapSleepEditState state;
  final Future<bool> Function() onSave;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final idle = !state.busy;
    return Row(
      children: [
        if (state.canDelete) ...[
          DuoNapRoundButton(
            icon: Icons.delete_outline_rounded,
            label: state.isWake ? 'Fshije këtë zgjim' : 'Fshije këtë gjumë',
            size: 56,
            onTap: idle ? () => _run(context, onDelete) : null,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: DuoNapPillButton(
            label: 'Ruaje',
            color: DuoNapColors.text,
            height: 56,
            onTap: idle ? () => _run(context, onSave) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _run(BuildContext context, Future<bool> Function() action) async {
    final done = await action();
    if (done && context.mounted) Navigator.of(context).pop();
  }
}
