/// This phone's link to the shared family, as the settings screen shows it.
class DuoNapFamilyStatus {
  const DuoNapFamilyStatus({
    required this.linked,
    this.joinCode,
    this.joinCodeExpires,
    this.members = 0,
  });

  static const DuoNapFamilyStatus unlinked = DuoNapFamilyStatus(linked: false);

  final bool linked;

  /// The code the other phone types to join. Null until it is known.
  final String? joinCode;
  final DateTime? joinCodeExpires;

  /// How many phones share the family. Zero until the family has loaded.
  final int members;
}

/// A new join code and the moment it stops working.
class DuoNapJoinCode {
  const DuoNapJoinCode({required this.code, required this.expires});

  final String code;
  final DateTime expires;
}
