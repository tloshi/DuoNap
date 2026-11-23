import 'package:flutter/material.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_plan_item.dart';
import '../duonap_today_formatters.dart';

/// The full day as a list: wake-up, each nap, night. Logged rows and the
/// wake-up row can be tapped to correct them.
class DuoNapPlanCard extends StatelessWidget {
  const DuoNapPlanCard({
    super.key,
    required this.plan,
    required this.secondInitial,
    required this.onRowTap,
  });

  final List<DuoNapPlanItem> plan;

  /// Shown beside a time that differs for the second baby.
  final String secondInitial;
  final ValueChanged<DuoNapPlanItem> onRowTap;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DuoNapColors.muted,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
      decoration: BoxDecoration(
        color: DuoNapColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Plani i sotëm', style: small),
                Text('për të dyja', style: small),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final item in plan)
            _PlanRow(
              item: item,
              secondInitial: secondInitial,
              onTap: _canEdit(item) ? () => onRowTap(item) : null,
            ),
        ],
      ),
    );
  }

  /// Something logged can be corrected. The wake-up can always be set by hand.
  bool _canEdit(DuoNapPlanItem item) {
    return !item.isPredicted || item.kind == DuoNapPlanKind.wake;
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item, required this.secondInitial, required this.onTap});

  final DuoNapPlanItem item;
  final String secondInitial;
  final VoidCallback? onTap;

  static const Duration _range = Duration(minutes: 15);

  bool get _active {
    return item.status == DuoNapPlanStatus.next ||
        item.status == DuoNapPlanStatus.overdue ||
        item.status == DuoNapPlanStatus.ongoing;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strong = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final muted = textTheme.bodySmall?.copyWith(color: DuoNapColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: _active ? DuoNapColors.highlight : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(DuoNapFormat.clock(item.start), style: strong),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: DuoNapFormat.title(item),
                      style: strong,
                      children: [TextSpan(text: _detail(), style: muted)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _detail() {
    final parts = <String>[];
    if (item.kind == DuoNapPlanKind.nap) {
      final prefix = item.isPredicted ? 'rreth ' : '';
      parts.add('$prefix${DuoNapFormat.duration(item.expected)}');
    }
    final second = item.secondStart;
    if (second != null) {
      parts.add('$secondInitial ${DuoNapFormat.clock(second)}');
    }
    return parts.isEmpty ? '' : '   ${parts.join(' · ')}';
  }

  Widget _trailing() {
    return switch (item.status) {
      DuoNapPlanStatus.done => const Icon(
          Icons.check_rounded,
          size: 18,
          color: DuoNapColors.muted,
          semanticLabel: 'U krye',
        ),
      DuoNapPlanStatus.ongoing => const _Pill(label: 'po fle'),
      DuoNapPlanStatus.overdue => const _Pill(label: 'tani'),
      DuoNapPlanStatus.next => _Pill(label: _window()),
      DuoNapPlanStatus.upcoming => const SizedBox.shrink(),
    };
  }

  String _window() {
    final from = DuoNapFormat.clock(item.start.subtract(_range));
    final to = DuoNapFormat.clock(item.start.add(_range));
    return '$from – $to';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DuoNapColors.ground,
          fontWeight: FontWeight.w700,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DuoNapColors.text,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: style),
    );
  }
}
