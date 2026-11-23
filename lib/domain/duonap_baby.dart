enum DuoNapBabyId { first, second }

class DuoNapBaby {
  const DuoNapBaby({required this.id, required this.name});

  final DuoNapBabyId id;
  final String name;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
}
