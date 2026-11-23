import '../domain/duonap_plan_item.dart';

/// Turns two babies' plans into one shared plan.
///
/// When both babies are predicted to sleep within the tolerance of each other,
/// they share one time: the earlier one for naps (a tired baby does not wait),
/// the later one for night (both need their last wake window). When the times
/// are further apart, the first baby's time stays and the second is kept beside it.
class DuoNapTwinPlanMerger {
  const DuoNapTwinPlanMerger();

  static const Duration _syncTolerance = Duration(minutes: 20);

  List<DuoNapPlanItem> merge(
    List<DuoNapPlanItem> first,
    List<DuoNapPlanItem> second,
  ) {
    final merged = <DuoNapPlanItem>[];
    for (final item in first) {
      final twin = _match(second, item);
      merged.add(twin == null ? item : _mergeItem(item, twin));
    }
    return merged;
  }

  DuoNapPlanItem? _match(List<DuoNapPlanItem> items, DuoNapPlanItem item) {
    for (final candidate in items) {
      final same = candidate.kind == item.kind && candidate.index == item.index;
      if (same) return candidate;
    }
    return null;
  }

  DuoNapPlanItem _mergeItem(DuoNapPlanItem a, DuoNapPlanItem b) {
    final gap = a.start.difference(b.start).abs();
    if (gap > _syncTolerance) return a.copyWith(secondStart: b.start);
    if (!a.isPredicted || !b.isPredicted) return a;
    final earlier = a.start.isBefore(b.start) ? a.start : b.start;
    final later = a.start.isBefore(b.start) ? b.start : a.start;
    final shared = a.kind == DuoNapPlanKind.night ? later : earlier;
    return a.copyWith(start: shared);
  }
}
