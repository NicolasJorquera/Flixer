import 'package:flixer/global/constants.dart';
import 'package:flixer/global/strings.dart';
import 'package:flutter/material.dart';

/// Row of platform logos that filters both tabs; several can be picked. With
/// platforms selected the other tiles fade out, so the choice reads without a
/// colored outline. An empty selection means all platforms.
class ProviderBar extends StatelessWidget {
  final List providers;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  const ProviderBar(
      {super.key,
      required this.providers,
      required this.selectedIds,
      required this.onChanged});

  static const double height = 66;
  static const double _tileSize = 46;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: [
          tile(
            context,
            id: null,
            label: tr('allPlatforms'),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceTint,
              alignment: Alignment.center,
              child: Text(
                tr('allPlatforms'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ),
          for (final provider in providers)
            tile(
              context,
              id: provider['provider_id'],
              label: provider['provider_name'],
              child: Image.network(
                image_resize + provider['logo_path'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Theme.of(context).colorScheme.surfaceTint),
              ),
            ),
        ],
      ),
    );
  }

  Widget tile(BuildContext context,
      {required int? id, required String label, required Widget child}) {
    final selected =
        id == null ? selectedIds.isEmpty : selectedIds.contains(id);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            if (id == null) return onChanged({});
            onChanged(selected
                ? (Set.of(selectedIds)..remove(id))
                : (Set.of(selectedIds)..add(id)));
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            // "All" leaves every tile bright; picking platforms dims the rest.
            opacity: selected || selectedIds.isEmpty ? 1 : 0.3,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: selected && id != null ? 1.08 : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _tileSize,
                  height: _tileSize,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
