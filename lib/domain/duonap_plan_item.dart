enum DuoNapPlanKind { wake, nap, night }

enum DuoNapPlanStatus { done, ongoing, next, overdue, upcoming }

/// One line of the day plan: the wake-up, a nap, or night sleep.
class DuoNapPlanItem {
  const DuoNapPlanItem({
    required this.kind,
    required this.index,
    required this.start,
    required this.expected,
    required this.status,
    this.secondStart,
  });

  final DuoNapPlanKind kind;

  /// Nap number starting at 1. Zero for the wake-up and for night sleep.
  final int index;

  final DateTime start;
  final Duration expected;
  final DuoNapPlanStatus status;

  /// Set only in the shared plan, when the second baby's time differs too much.
  final DateTime? secondStart;

  DateTime get end => start.add(expected);

  bool get isPredicted {
    return status == DuoNapPlanStatus.next ||
        status == DuoNapPlanStatus.overdue ||
        status == DuoNapPlanStatus.upcoming;
  }

  DuoNapPlanItem copyWith({
    DateTime? start,
    DuoNapPlanStatus? status,
    DateTime? secondStart,
  }) {
    return DuoNapPlanItem(
      kind: kind,
      index: index,
      start: start ?? this.start,
      expected: expected,
      status: status ?? this.status,
      secondStart: secondStart ?? this.secondStart,
    );
  }
}
