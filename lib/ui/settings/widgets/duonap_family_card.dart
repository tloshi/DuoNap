import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/duonap_theme.dart';
import '../../../domain/duonap_family.dart';
import '../../common/duonap_error_text.dart';
import '../../common/duonap_pill_button.dart';
import '../../today/duonap_today_formatters.dart';
import '../duonap_family_state.dart';
import '../duonap_family_view_model.dart';
import 'duonap_settings_cards.dart';

/// "Familja": link this phone with the other parent's phone by a short code.
class DuoNapFamilyCard extends ConsumerWidget {
  const DuoNapFamilyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duoNapFamilyViewModelProvider);
    final viewModel = ref.read(duoNapFamilyViewModelProvider.notifier);
    final status = state.status;
    final error = state.error;
    return DuoNapSettingsCard(
      title: 'Familja',
      children: [
        if (status == null)
          const Center(child: CircularProgressIndicator())
        else if (status.linked)
          _Linked(status: status, onRenew: state.busy ? null : viewModel.renewCode)
        else
          _Unlinked(state: state, viewModel: viewModel),
        if (error != null) DuoNapErrorLine(message: error),
      ],
    );
  }
}

class _Linked extends StatelessWidget {
  const _Linked({required this.status, required this.onRenew});

  final DuoNapFamilyStatus status;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: DuoNapColors.muted);
    final expires = status.joinCodeExpires;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.members > 0)
          Text('Telefonat e lidhur: ${status.members}', style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text('Kodi për telefonin tjetër', style: muted),
        Text(
          status.joinCode ?? '…',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 4),
        ),
        if (expires != null)
          Text('Vlen deri ${DuoNapFormat.date(expires)}, ${DuoNapFormat.clock(expires)}', style: muted),
        const SizedBox(height: 14),
        DuoNapPillButton(
          label: 'Kod i ri',
          color: DuoNapColors.raised,
          textColor: DuoNapColors.text,
          height: 56,
          onTap: onRenew,
        ),
      ],
    );
  }
}

class _Unlinked extends StatelessWidget {
  const _Unlinked({required this.state, required this.viewModel});

  final DuoNapFamilyState state;
  final DuoNapFamilyViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final soft = textTheme.bodyMedium?.copyWith(color: DuoNapColors.soft, height: 1.4);
    final idle = !state.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Lidhe këtë telefon me telefonin tjetër, që të dy të shohin të njëjtin plan.', style: soft),
        const SizedBox(height: 14),
        DuoNapPillButton(
          label: 'Krijo familjen',
          color: DuoNapColors.text,
          height: 56,
          onTap: idle ? viewModel.create : null,
        ),
        const SizedBox(height: 14),
        Center(child: Text('ose', style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted))),
        const SizedBox(height: 14),
        _CodeField(onChanged: viewModel.setCode),
        const SizedBox(height: 10),
        DuoNapPillButton(
          label: 'Bashkohu',
          color: DuoNapColors.raised,
          textColor: DuoNapColors.text,
          height: 56,
          onTap: idle && state.code.trim().isNotEmpty ? viewModel.join : null,
        ),
        const SizedBox(height: 8),
        Text(
          'Kur bashkohesh, regjistrimet e këtij telefoni zëvendësohen me ato të familjes.',
          style: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
        ),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextFormField(
      onChanged: onChanged,
      maxLength: 8,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      cursorColor: DuoNapColors.text,
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 3),
      decoration: InputDecoration(
        labelText: 'Kodi nga telefoni tjetër',
        labelStyle: textTheme.bodySmall?.copyWith(color: DuoNapColors.muted),
        counterText: '',
        filled: true,
        fillColor: DuoNapColors.inset,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
