import 'package:flutter/material.dart';

import '../../app/duonap_theme.dart';

/// What the user reads when a service returns a failure code.
/// Codes come from the services; the text is Albanian like the rest of the UI.
String duoNapErrorText(String code) {
  return switch (code) {
    'IN_FUTURE' => 'Ora nuk mund të jetë në të ardhmen.',
    'END_BEFORE_START' => 'Fundi duhet të jetë pas fillimit.',
    'END_MISSING' => 'Mungon ora e fundit.',
    'WAKE_OUT_OF_RANGE' => 'Zgjimi duhet të jetë mes orës 05:00 dhe 14:00.',
    'BEDTIME_OUT_OF_RANGE' => 'Gjumi i natës duhet të jetë pas orës 14:00.',
    'OUT_OF_PLACE' => 'Kjo orë nuk i përshtatet këtij gjumi.',
    'OVERLAP' => 'Ky gjumë mbivendoset me një gjumë tjetër.',
    'NOTHING_SELECTED' => 'Zgjidh të paktën një fëmijë.',
    'NAME_EMPTY' => 'Shkruaj një emër.',
    'NAME_TOO_LONG' => 'Emri është shumë i gjatë.',
    _ => 'Diçka nuk shkoi. Provo përsëri.',
  };
}

/// One centred line under a form, in the first baby's warm colour.
class DuoNapErrorLine extends StatelessWidget {
  const DuoNapErrorLine({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DuoNapColors.first),
      ),
    );
  }
}
