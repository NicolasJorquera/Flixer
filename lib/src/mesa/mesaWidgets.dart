import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flutter/material.dart';

/// Chip for the table filters; selected chips are inverted like the rest of
/// the app's filters.
class MesaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const MesaChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.onBackground,
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.onBackground),
      onSelected: (_) => onTap(),
    );
  }
}

Text sectionTitle(BuildContext context, String text) => Text(text,
    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 17));

String mesaErrorText(Object error) {
  final reason = error is MesaUnavailable ? error.reason : '';
  switch (reason) {
    case 'not-found':
      return tr('mesaNotFound');
    case 'started':
      return tr('mesaStarted');
    case 'full':
      return tr('mesaFull');
    default:
      return tr('mesaOffline');
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Asks before leaving a table; returns to the home screen if confirmed.
Future<void> confirmLeave(BuildContext context, MesaSession session) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      title: Text(tr('leaveMesa'),
          style: Theme.of(context).textTheme.displayMedium),
      content: session.isHost && session.state.value?.code != ''
          ? Text(tr('leaveMesaHost'),
              style: Theme.of(context).textTheme.displaySmall)
          : null,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground))),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('leave'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.primary))),
      ],
    ),
  );
  if (leave != true || !context.mounted) return;
  await session.leave();
  if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
}

/// Primary action button used across the table screens.
class MesaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const MesaButton(
      {super.key, required this.label, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
