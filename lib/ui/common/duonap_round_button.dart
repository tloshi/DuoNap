import 'package:flutter/material.dart';

import '../../app/duonap_theme.dart';

/// A round icon button. [label] is read out by screen readers.
class DuoNapRoundButton extends StatelessWidget {
  const DuoNapRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
  });

  static const double _iconRatio = 0.42;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: DuoNapColors.highlight,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * _iconRatio, color: DuoNapColors.text),
          ),
        ),
      ),
    );
  }
}
