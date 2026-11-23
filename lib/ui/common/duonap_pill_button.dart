import 'package:flutter/material.dart';

import '../../app/duonap_theme.dart';

/// The app's main button: a full pill, at least 56 px high, one thumb away.
/// A null [onTap] shows it faded and ignores taps.
class DuoNapPillButton extends StatelessWidget {
  const DuoNapPillButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.height = 60,
    this.textColor = DuoNapColors.ground,
  });

  static const int _fadedAlpha = 90;

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double height;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
    return Material(
      color: enabled ? color : color.withAlpha(_fadedAlpha),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(label, textAlign: TextAlign.center, style: style),
          ),
        ),
      ),
    );
  }
}
