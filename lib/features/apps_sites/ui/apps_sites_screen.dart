import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Phase 1 placeholder for **Apps & Sites** (portals, telehealth, IEP).
///
/// URLs and notes only — never passwords — once the feature ships.
class AppsSitesScreen extends ConsumerWidget {
  const AppsSitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(activePersonProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apps & Sites')),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add someone to the roster first — saved links are scoped '
                  'per person.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Apps & Sites · ${person.displayName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Portal URLs, telehealth logins (never passwords — use a '
                'password manager), and short notes will be stored here with '
                'the same per-person encryption as the rest of the app.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        },
      ),
    );
  }
}
