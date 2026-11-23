import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_baby.dart';
import '../duonap_sleep_edit_state.dart';

/// Three segments: first baby, second baby, both. Unavailable ones are faded.
class DuoNapTargetSelector extends StatelessWidget {
  const DuoNapTargetSelector({
    super.key,
    required this.babies,
    required this.selected,
    required this.available,
    required this.onSelect,
  });

  final List<DuoNapBaby> babies;
  final DuoNapEditTarget selected;
  final List<DuoNapEditTarget> available;
  final ValueChanged<DuoNapEditTarget> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DuoNapColors.inset,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          for (final target in DuoNapEditTarget.values)
            Expanded(child: _segment(context, target)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, DuoNapEditTarget target) {
    final isSelected = target == selected;
    final enabled = available.contains(target);
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _textColor(isSelected, enabled),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        );
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: isSelected ? _colorOf(target) : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onSelect(target) : null,
          child: SizedBox(
            height: 44,
            child: Center(child: Text(_labelOf(target), style: style)),
          ),
        ),
      ),
    );
  }

  String _labelOf(DuoNapEditTarget target) {
    final baby = DuoNapSleepEditState.babyOf(target);
    if (baby == null) return 'Të dyja';
    return babies.firstWhere((b) => b.id == baby).name;
  }

  Color _colorOf(DuoNapEditTarget target) {
    final baby = DuoNapSleepEditState.babyOf(target);
    return baby == null ? DuoNapColors.text : DuoNapColors.ofBaby(baby);
  }

  Color _textColor(bool isSelected, bool enabled) {
    if (isSelected) return DuoNapColors.ground;
    return enabled ? DuoNapColors.soft : DuoNapColors.handle;
  }
}
