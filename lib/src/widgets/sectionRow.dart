import 'package:flixer/global/strings.dart';
import 'package:flixer/src/widgets/posterCard.dart';
import 'package:flutter/material.dart';

const double sectionCardWidth = 120;

/// Header with "See all" plus a horizontal row of [PosterCard]s.
class SectionRow extends StatelessWidget {
  final String title;
  final List items;
  final VoidCallback? onSeeAll;
  const SectionRow(
      {super.key, required this.title, required this.items, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SectionFrame(
      title: title,
      onSeeAll: onSeeAll,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            PosterCard(item: items[index], width: sectionCardWidth),
      ),
    );
  }
}

/// A section that loads its own items; hides itself when there are none.
class FutureSectionRow extends StatefulWidget {
  final String title;
  final Future<List> Function() load;
  final VoidCallback? onSeeAll;
  const FutureSectionRow(
      {super.key, required this.title, required this.load, this.onSeeAll});

  @override
  State<FutureSectionRow> createState() => _FutureSectionRowState();
}

class _FutureSectionRowState extends State<FutureSectionRow> {
  late Future<List> items;

  @override
  void initState() {
    super.initState();
    items = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SectionFrame(
            title: widget.title,
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() {
                  items = widget.load();
                }),
                icon: Icon(Icons.refresh,
                    color: Theme.of(context).colorScheme.secondary),
                label: Text(
                  '${tr('sectionError')} · ${tr('retry')}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return SectionFrame(
            title: widget.title,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: sectionCardWidth,
                  height: sectionCardWidth * 1.5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.data!.isEmpty) return const SizedBox.shrink();
        return SectionRow(
          title: widget.title,
          items: snapshot.data!,
          onSeeAll: widget.onSeeAll,
        );
      },
    );
  }
}

class SectionFrame extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget child;
  const SectionFrame(
      {super.key, required this.title, required this.child, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 2),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ),
                  if (onSeeAll != null)
                    TextButton(
                      onPressed: onSeeAll,
                      child: Text(
                        tr('seeAll'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: PosterCard.heightFor(sectionCardWidth),
            child: child,
          ),
        ],
      ),
    );
  }
}
