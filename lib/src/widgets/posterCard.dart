import 'package:flixer/global/constants.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flutter/material.dart';

/// Poster with title, rating and year below; opens the detail page.
class PosterCard extends StatelessWidget {
  final Map item;
  final double width;
  const PosterCard({super.key, required this.item, required this.width});

  static const double textHeight = 46;
  static double heightFor(double width) => width * 1.5 + textHeight;

  @override
  Widget build(BuildContext context) {
    final String title = item['title'] ?? item['name'] ?? '';
    final String date = item['release_date'] ?? item['first_air_date'] ?? '';
    final String year = date.length >= 4 ? date.substring(0, 4) : '';
    final num votes = item['vote_count'] ?? 0;
    final String rating =
        votes > 0 ? (item['vote_average'] as num? ?? 0).toStringAsFixed(1) : '';

    return Semantics(
      button: true,
      label: [title, if (rating.isNotEmpty) '★ $rating', year].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MovieInfoPage(movie: item)),
          );
        },
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image_resize + item['poster_path'],
                  width: width,
                  height: width * 1.5,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null ? child : placeholder(context),
                  errorBuilder: (context, error, stackTrace) =>
                      placeholder(context),
                ),
              ),
              SizedBox(
                height: textHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (rating.isNotEmpty) ...[
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            year,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget placeholder(BuildContext context) => Container(
        width: width,
        height: width * 1.5,
        color: Theme.of(context).colorScheme.surfaceTint,
      );
}
