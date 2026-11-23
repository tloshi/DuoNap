import '../../domain/duonap_plan_item.dart';
import '../../domain/duonap_today_snapshot.dart';

class DuoNapFormat {
  const DuoNapFormat._();

  static const List<String> _weekdays = [
    'e hënë',
    'e martë',
    'e mërkurë',
    'e enjte',
    'e premte',
    'e shtunë',
    'e diel',
  ];

  static const List<String> _months = [
    'janar',
    'shkurt',
    'mars',
    'prill',
    'maj',
    'qershor',
    'korrik',
    'gusht',
    'shtator',
    'tetor',
    'nëntor',
    'dhjetor',
  ];

  static String clock(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

  /// Minutes after midnight as a clock time: 1275 is "21:15".
  static String minutesOfDay(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

  /// Month names after a day number in "rreth 20 dhjetorit".
  static const List<String> _monthsAfterDay = [
    'janarit',
    'shkurtit',
    'marsit',
    'prillit',
    'majit',
    'qershorit',
    'korrikut',
    'gushtit',
    'shtatorit',
    'tetorit',
    'nëntorit',
    'dhjetorit',
  ];

  /// "e martë 3 nëntor".
  static String date(DateTime day) {
    return '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';
  }

  /// "20 dhjetorit", for "mbërritja rreth 20 dhjetorit".
  static String arrival(DateTime day) => '${day.day} ${_monthsAfterDay[day.month - 1]}';

  /// "Sot, e hënë" for today, otherwise "E enjte, 26 nëntor".
  static String stepDay(DateTime day, DateTime today) {
    final weekday = _weekdays[day.weekday - 1];
    final sameDay = day.year == today.year && day.month == today.month && day.day == today.day;
    if (sameDay) return 'Sot, $weekday';
    final capital = weekday[0].toUpperCase() + weekday.substring(1);
    return '$capital, ${day.day} ${_months[day.month - 1]}';
  }

  static String duration(Duration value) {
    final minutes = value.inMinutes.abs();
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest min';
    if (rest == 0) return '$hours h';
    return '$hours h $rest min';
  }

  static String title(DuoNapPlanItem item) {
    return switch (item.kind) {
      DuoNapPlanKind.wake => 'Zgjimi',
      DuoNapPlanKind.nap => 'Gjumi ${item.index}',
      DuoNapPlanKind.night => 'Nata',
    };
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// The two lines in the middle of the ring: what is next, and when.
class DuoNapHeadline {
  const DuoNapHeadline({required this.label, required this.value});

  factory DuoNapHeadline.of(DuoNapTodaySnapshot snapshot) {
    final item = _current(snapshot.plan);
    if (item == null) {
      return const DuoNapHeadline(label: 'Dita u krye', value: 'Natën e mirë');
    }
    final title = DuoNapFormat.title(item);
    if (item.status == DuoNapPlanStatus.ongoing) {
      return DuoNapHeadline(
        label: '$title deri rreth',
        value: DuoNapFormat.clock(item.end),
      );
    }
    if (item.status == DuoNapPlanStatus.overdue) {
      return DuoNapHeadline(
        label: '$title duhej në',
        value: DuoNapFormat.clock(item.start),
      );
    }
    final wait = item.start.difference(snapshot.now);
    return DuoNapHeadline(
      label: '$title për',
      value: DuoNapFormat.duration(wait),
    );
  }

  final String label;
  final String value;

  static DuoNapPlanItem? _current(List<DuoNapPlanItem> plan) {
    for (final item in plan) {
      final active = item.status == DuoNapPlanStatus.ongoing ||
          item.status == DuoNapPlanStatus.next ||
          item.status == DuoNapPlanStatus.overdue;
      if (active) return item;
    }
    return null;
  }
}
