import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_shift.dart';
import '../../common/duonap_pill_button.dart';
import '../../common/duonap_sheet_frame.dart';
import '../../today/duonap_today_formatters.dart';

/// "Ndrysho synimin": pick the night target, or stop the path.
class DuoNapTargetSheet extends StatelessWidget {
  const DuoNapTargetSheet({
    super.key,
    required this.current,
    required this.onPick,
    required this.onStop,
  });

  final int current;
  final Future<void> Function(int minutes) onPick;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: DuoNapColors.muted);
    return DuoNapSheetFrame(
      title: 'Synimi i natës',
      children: [
        Text(
          '19:30 sa kohë flenë tre gjume në ditë, 19:00 kur kalojnë në dy.',
          style: muted,
        ),
        Row(
          children: [
            for (final minutes in DuoNapShiftSetup.targetChoices) ...[
              if (minutes != DuoNapShiftSetup.targetChoices.first) const SizedBox(width: 8),
              Expanded(child: _choice(context, minutes)),
            ],
          ],
        ),
        DuoNapPillButton(
          label: 'Ndalo rrugën',
          color: DuoNapColors.raised,
          textColor: DuoNapColors.first,
          height: 56,
          onTap: () => _close(context, onStop),
        ),
      ],
    );
  }

  Widget _choice(BuildContext context, int minutes) {
    final selected = minutes == current;
    return DuoNapPillButton(
      label: DuoNapFormat.minutesOfDay(minutes),
      color: selected ? DuoNapColors.text : DuoNapColors.highlight,
      textColor: selected ? DuoNapColors.ground : DuoNapColors.soft,
      height: 56,
      onTap: () => _close(context, () => onPick(minutes)),
    );
  }

  Future<void> _close(BuildContext context, Future<void> Function() action) async {
    Navigator.of(context).pop();
    await action();
  }
}
