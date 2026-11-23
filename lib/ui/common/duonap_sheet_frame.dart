import 'package:flutter/material.dart';

import '../../app/duonap_theme.dart';
import 'duonap_round_button.dart';

/// Opens [sheet] as a bottom sheet over a transparent background, so the
/// sheet draws its own rounded frame.
Future<void> showDuoNapSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

/// The rounded bottom sheet from the "D · Dialogu" mockup: handle, title with
/// a close button, then [children] stacked with even gaps.
class DuoNapSheetFrame extends StatelessWidget {
  const DuoNapSheetFrame({super.key, required this.title, required this.children});

  static const double gap = 18;

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: DuoNapColors.sheet,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: DuoNapColors.sheetBorder),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              const SizedBox(height: gap),
              _Header(title: title),
              for (final child in children) ...[const SizedBox(height: gap), child],
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: DuoNapColors.handle,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        DuoNapRoundButton(
          icon: Icons.close_rounded,
          label: 'Mbyll',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
