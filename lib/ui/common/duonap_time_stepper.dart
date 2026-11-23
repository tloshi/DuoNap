import 'package:flutter/material.dart';

import '../../app/duonap_theme.dart';
import 'duonap_round_button.dart';

/// A time with minus and plus buttons on either side, as in "D · Dialogu".
class DuoNapTimeStepper extends StatelessWidget {
  const DuoNapTimeStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.minusLabel,
    required this.plusLabel,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  /// Read out by screen readers, e.g. "Fillimi një minutë më herët".
  final String minusLabel;
  final String plusLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DuoNapColors.inset,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: DuoNapColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DuoNapRoundButton(
                icon: Icons.remove_rounded,
                label: minusLabel,
                onTap: onMinus,
              ),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              DuoNapRoundButton(
                icon: Icons.add_rounded,
                label: plusLabel,
                onTap: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
