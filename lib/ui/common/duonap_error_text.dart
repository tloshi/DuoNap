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
    'ALREADY_RUNNING' => 'Rruga ka nisur tashmë.',
    'NOT_RUNNING' => 'Rruga nuk ka nisur ende.',
    'TARGET_INVALID' => 'Zgjidh një nga synimet.',
    'CODE_INVALID' => 'Kodi ka 6 shkronja ose shifra.',
    'CODE_UNKNOWN' => 'Ky kod nuk njihet ose ka skaduar.',
    'OFFLINE' => 'Nuk ka lidhje me internetin. Provo përsëri.',
    'SYNC_FAILED' => 'Sinkronizimi me telefonin tjetër dështoi.',
    'ALREADY_LINKED' => 'Ky telefon është i lidhur tashmë me familjen.',
    'NOT_LINKED' => 'Ky telefon nuk është i lidhur me një familje.',
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
