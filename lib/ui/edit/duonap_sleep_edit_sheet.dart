import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_plan_item.dart';
import '../common/duonap_error_text.dart';
import '../common/duonap_pill_button.dart';
import '../common/duonap_round_button.dart';
import 'duonap_sleep_edit_state.dart';
import 'duonap_sleep_edit_view_model.dart';
import 'widgets/duonap_sleep_edit_parts.dart';
import 'widgets/duonap_target_selector.dart';

/// Opens the sheet for whatever the edit view model has loaded.
Future<void> showDuoNapSleepEditSheet(
  BuildContext context,
  List<DuoNapBaby> babies,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DuoNapSleepEditSheet(babies: babies),
  );
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: DuoNapColors.sheet,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: DuoNapColors.sheetBorder),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              const SizedBox(height: 18),
              _Header(title: _title(state)),
              const SizedBox(height: 18),
              DuoNapTargetSelector(
                babies: babies,
                selected: state.target,
                available: state.targets,
                onSelect: viewModel.select,
              ),
              const SizedBox(height: 18),
              DuoNapEditSummary(state: state),
              const SizedBox(height: 18),
              DuoNapEditTimes(
                state: state,
                onStart: viewModel.nudgeStart,
                onEnd: viewModel.nudgeEnd,
              ),
              if (error != null) DuoNapErrorLine(message: error),
              const SizedBox(height: 18),
              _Actions(state: state, onSave: viewModel.save, onDelete: viewModel.delete),
            ],
          ),
        ),
      ),
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

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: DuoNapColors.handle,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        DuoNapRoundButton(
          icon: Icons.close_rounded,
          label: 'Mbyll',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
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
