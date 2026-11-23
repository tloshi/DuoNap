import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../common/duonap_error_text.dart';
import '../common/duonap_pill_button.dart';
import '../common/duonap_round_button.dart';
import 'duonap_settings_view_model.dart';
import 'widgets/duonap_settings_cards.dart';

/// Baby names, planned bedtime and usual wake time.
class DuoNapSettingsScreen extends ConsumerWidget {
  const DuoNapSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapSettingsViewModelProvider);
    final viewModel = ref.read(duoNapSettingsViewModelProvider.notifier);
    final draft = state.draft;
    final error = state.error;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _TopBar(),
            const SizedBox(height: 20),
            if (draft == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              DuoNapSettingsNamesCard(draft: draft, onName: viewModel.setName),
              const SizedBox(height: 14),
              DuoNapSettingsTimesCard(
                draft: draft,
                viewModel: viewModel,
                pathRunning: state.pathRunning,
              ),
              const SizedBox(height: 20),
              DuoNapPillButton(
                label: 'Ruaje',
                color: DuoNapColors.text,
                height: 56,
                onTap: state.busy ? null : () => _save(context, viewModel),
              ),
            ],
            if (error != null) DuoNapErrorLine(message: error),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, DuoNapSettingsViewModel viewModel) async {
    final saved = await viewModel.save();
    if (saved && context.mounted) Navigator.of(context).pop();
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
          'Cilësimet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
