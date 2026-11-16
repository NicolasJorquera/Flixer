import 'package:flutter/material.dart';

import 'package:flixer/billing/purchases.dart';
import 'package:flixer/billing/removeAds.dart';
import 'package:flixer/global/strings.dart';

/// «Sin anuncios» in the settings sheet: Play's price, buy and restore.
class RemoveAdsTile extends StatefulWidget {
  const RemoveAdsTile({super.key});

  @override
  State<RemoveAdsTile> createState() => _RemoveAdsTileState();
}

class _RemoveAdsTileState extends State<RemoveAdsTile> {
  @override
  void initState() {
    super.initState();
    RemoveAds.instance.loadProduct();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.displaySmall?.copyWith(
        color: theme.colorScheme.onBackground, fontSize: 13);
    return ValueListenableBuilder<RemoveAdsState>(
      valueListenable: RemoveAds.instance,
      builder: (context, state, _) {
        final busy = state.flow == PurchaseFlow.busy;
        final message = state.owned ? _ownedMessage(state.flow) : _message(state.flow);
        return Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Icon(Icons.block, color: theme.colorScheme.onBackground),
                ),
                Expanded(
                  child: Text(tr('removeAds'),
                      style: theme.textTheme.displayMedium?.copyWith(fontSize: 18)),
                ),
                if (!state.owned)
                  FilledButton(
                    onPressed: busy ? null : RemoveAds.instance.buy,
                    child: Text(state.price == null
                        ? tr('removeAdsBuy')
                        : '${tr('removeAdsBuy')} · ${state.price}'),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(54, 4, 0, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(message ?? tr('removeAdsPitch'), style: small),
                ),
              ),
              if (!state.owned)
                Padding(
                  padding: const EdgeInsets.only(left: 42),
                  child: TextButton(
                    onPressed: busy ? null : RemoveAds.instance.restore,
                    child: Text(tr('removeAdsRestore')),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _ownedMessage(PurchaseFlow flow) => switch (flow) {
        PurchaseFlow.purchased => tr('removeAdsThanks'),
        PurchaseFlow.restored => tr('removeAdsRestored'),
        _ => tr('removeAdsOwned'),
      };

  String? _message(PurchaseFlow flow) => switch (flow) {
        PurchaseFlow.busy => tr('removeAdsBusy'),
        PurchaseFlow.pending => tr('removeAdsPending'),
        PurchaseFlow.nothingToRestore => tr('removeAdsNothing'),
        PurchaseFlow.canceled => tr('removeAdsCanceled'),
        PurchaseFlow.error => tr('removeAdsError'),
        PurchaseFlow.unavailable => tr('removeAdsUnavailable'),
        _ => null,
      };
}
