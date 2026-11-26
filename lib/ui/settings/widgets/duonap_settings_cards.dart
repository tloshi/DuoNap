import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_settings.dart';
import '../../common/duonap_time_stepper.dart';
import '../../today/duonap_today_formatters.dart';
import '../duonap_settings_view_model.dart';

/// A settings card: a small title, then [children] stacked.
class DuoNapSettingsCard extends StatelessWidget {
  const DuoNapSettingsCard({super.key, required this.title, required this.children});

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

/// "Emrat": one text field per baby, labelled in that baby's colour.
class DuoNapSettingsNamesCard extends StatelessWidget {
  const DuoNapSettingsNamesCard({super.key, required this.draft, required this.onName});

  final DuoNapSettings draft;
  final void Function(DuoNapBabyId id, String name) onName;

  @override
  Widget build(BuildContext context) {
    return DuoNapSettingsCard(
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

/// "Orët": bedtime and usual wake time. While the path toward 19:00 – 07:00
/// runs, it sets both, so the steppers give way to a note.
class DuoNapSettingsTimesCard extends StatelessWidget {
  const DuoNapSettingsTimesCard({
    super.key,
    required this.draft,
    required this.viewModel,
    required this.pathRunning,
  });

  final DuoNapSettings draft;
  final DuoNapSettingsViewModel viewModel;
  final bool pathRunning;

  @override
  Widget build(BuildContext context) {
    if (pathRunning) {
      return DuoNapSettingsCard(
        title: 'Orët',
        children: [
          Text(
            'Rruga drejt 19:00 – 07:00 po i cakton këto orë. Ndalo rrugën për t\'i ndryshuar këtu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DuoNapColors.soft),
          ),
        ],
      );
    }
    const step = '${DuoNapSettingsViewModel.stepMinutes} minuta';
    return DuoNapSettingsCard(
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
