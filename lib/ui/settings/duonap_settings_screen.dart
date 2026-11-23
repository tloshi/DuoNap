import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_theme.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_settings.dart';
import '../common/duonap_error_text.dart';
import '../common/duonap_pill_button.dart';
import '../common/duonap_round_button.dart';
import '../common/duonap_time_stepper.dart';
import '../today/duonap_today_formatters.dart';
import 'duonap_settings_view_model.dart';

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
              _NamesCard(draft: draft, onName: viewModel.setName),
              const SizedBox(height: 14),
              _TimesCard(draft: draft, viewModel: viewModel),
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

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _NamesCard extends StatelessWidget {
  const _NamesCard({required this.draft, required this.onName});

  final DuoNapSettings draft;
  final void Function(DuoNapBabyId id, String name) onName;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Emrat',
      children: [
        _NameField(label: 'Binjakja e parë', baby: draft.baby(DuoNapBabyId.first), onName: onName),
        const SizedBox(height: 12),
        _NameField(label: 'Binjakja e dytë', baby: draft.baby(DuoNapBabyId.second), onName: onName),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.label, required this.baby, required this.onName});

  final String label;
  final DuoNapBaby baby;
  final void Function(DuoNapBabyId id, String name) onName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextFormField(
      initialValue: baby.name,
      maxLength: DuoNapSettings.maxNameLength,
      textCapitalization: TextCapitalization.words,
      cursorColor: DuoNapColors.text,
      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      onChanged: (name) => onName(baby.id, name),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodySmall?.copyWith(color: DuoNapColors.ofBaby(baby.id)),
        counterText: '',
        filled: true,
        fillColor: DuoNapColors.inset,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TimesCard extends StatelessWidget {
  const _TimesCard({required this.draft, required this.viewModel});

  final DuoNapSettings draft;
  final DuoNapSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    const step = '${DuoNapSettingsViewModel.stepMinutes} minuta';
    return _Card(
      title: 'Orët',
      children: [
        DuoNapTimeStepper(
          label: 'Gjumi i natës',
          value: DuoNapFormat.minutesOfDay(draft.plannedBedtimeMinutes),
          onMinus: () => viewModel.nudgeBedtime(-1),
          onPlus: () => viewModel.nudgeBedtime(1),
          minusLabel: 'Gjumi i natës $step më herët',
          plusLabel: 'Gjumi i natës $step më vonë',
        ),
        const SizedBox(height: 10),
        DuoNapTimeStepper(
          label: 'Zgjimi i zakonshëm',
          value: DuoNapFormat.minutesOfDay(draft.usualWakeMinutes),
          onMinus: () => viewModel.nudgeWake(-1),
          onPlus: () => viewModel.nudgeWake(1),
          minusLabel: 'Zgjimi $step më herët',
          plusLabel: 'Zgjimi $step më vonë',
        ),
      ],
    );
  }
}
