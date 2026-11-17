import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaHomeView.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Invitations to try the group table from the rest of the app.
class MesaPromo {
  MesaPromo._();

  static const _prefsKey = 'mesaCardDismissed';

  /// Whether the home card is still shown; it goes away once dismissed or
  /// once it was used to open the table.
  static final ValueNotifier<bool> showCard = ValueNotifier(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    showCard.value = !(prefs.getBool(_prefsKey) ?? false);
  }

  static Future<void> dismissCard() async {
    showCard.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  static void open(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MesaHomeView()));
  }
}

/// Card at the top of the home feed that explains the group table.
class MesaPromoCard extends StatelessWidget {
  const MesaPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MesaPromo.showCard,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceTint,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                MesaPromo.dismissCard();
                MesaPromo.open(context);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 4, 12),
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded,
                        size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('mesaPromoTitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(tr('mesaPromoBody'),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary)),
                          const SizedBox(height: 6),
                          Text('${tr('tryIt')} →',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: tr('dismiss'),
                      onPressed: MesaPromo.dismissCard,
                      icon: Icon(Icons.close,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One-line nudge, e.g. above My list when there are several titles to pick
/// from.
class MesaPromoHint extends StatelessWidget {
  final String text;
  const MesaPromoHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => MesaPromo.open(context),
      leading: Icon(Icons.groups_outlined,
          color: Theme.of(context).colorScheme.primary),
      title: Text(text, style: Theme.of(context).textTheme.displaySmall),
      trailing: Icon(Icons.chevron_right,
          color: Theme.of(context).colorScheme.secondary),
    );
  }
}
