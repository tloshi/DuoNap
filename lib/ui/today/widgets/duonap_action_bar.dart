import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_today_snapshot.dart';

/// Three big buttons: first baby, both at once, second baby.
class DuoNapActionBar extends StatelessWidget {
  const DuoNapActionBar({
    super.key,
    required this.snapshot,
    required this.onBaby,
    required this.onBoth,
  });

  final DuoNapTodaySnapshot snapshot;
  final ValueChanged<DuoNapBabyId> onBaby;

  /// Called with the state both babies should move to: true means asleep.
  final ValueChanged<bool> onBoth;

  @override
  Widget build(BuildContext context) {
    final bothAsleep = snapshot.bothAsleep;
    return Row(
      children: [
        Expanded(flex: 10, child: _babyButton(DuoNapBabyId.first)),
        const SizedBox(width: 8),
        Expanded(
          flex: 13,
          child: _PillButton(
            label: bothAsleep ? 'Të dyja\nu zgjuan' : 'Të dyja\nfjetën',
            color: DuoNapColors.text,
            onTap: () => onBoth(!bothAsleep),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 10, child: _babyButton(DuoNapBabyId.second)),
      ],
    );
  }

  Widget _babyButton(DuoNapBabyId id) {
    final baby = DuoNapFamily.byId(id);
    final asleep = snapshot.statuses[id]?.asleep ?? false;
    return _PillButton(
      label: asleep ? '${baby.name}\nu zgjua' : '${baby.name}\nfjeti',
      color: DuoNapColors.ofBaby(id),
      onTap: () => onBaby(id),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: DuoNapColors.ground,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
    return Material(
      color: color,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(label, textAlign: TextAlign.center, style: style),
          ),
        ),
      ),
    );
  }
}
