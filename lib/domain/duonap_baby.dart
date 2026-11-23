enum DuoNapBabyId { first, second }

class DuoNapBaby {
  const DuoNapBaby({required this.id, required this.name});

  final DuoNapBabyId id;
  final String name;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
}

/// The two babies the app tracks. Names move to settings once there is a settings screen.
class DuoNapFamily {
  const DuoNapFamily._();

  static const List<DuoNapBaby> babies = [
    DuoNapBaby(id: DuoNapBabyId.first, name: 'Elena'),
    DuoNapBaby(id: DuoNapBabyId.second, name: 'Diana'),
  ];

  static DuoNapBaby byId(DuoNapBabyId id) {
    return babies.firstWhere((baby) => baby.id == id);
  }
}
