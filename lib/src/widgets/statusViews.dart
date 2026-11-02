import 'package:flixer/global/strings.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Shown when a TMDB request fails, with a button to try again.
class ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: 50,
            ),
            const SizedBox(height: 15),
            Text(
              tr('errorTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 5),
            Text(
              tr('errorBody'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh,
                  color: Theme.of(context).colorScheme.onBackground),
              label: Text(
                tr('retry'),
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
