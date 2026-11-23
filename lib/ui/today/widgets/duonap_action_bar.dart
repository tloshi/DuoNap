import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../../../domain/duonap_today_snapshot.dart';
import '../../common/duonap_pill_button.dart';

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
          child: DuoNapPillButton(
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
    final name = snapshot.baby(id).name;
    final asleep = snapshot.statuses[id]?.asleep ?? false;
    return DuoNapPillButton(
      label: asleep ? '$name\nu zgjua' : '$name\nfjeti',
      color: DuoNapColors.ofBaby(id),
      onTap: () => onBaby(id),
    );
  }
}
