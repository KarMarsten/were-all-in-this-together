import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_avatar.dart';

/// The roster of People the user has added.
///
/// This screen is deliberately unopinionated about who the "active" Person
/// is — it's a directory, not a selector. Active-person semantics land in
/// the follow-up wire-up PR.
class PeopleListScreen extends ConsumerWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.personNew),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add someone'),
      ),
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (people) {
          if (people.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) => _PersonTile(person: people[i]),
          );
        },
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final subtitle = _composeSubtitle(person);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: PersonAvatar(person: person),
        title: Text(person.displayName),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.personEdit(person.id)),
      ),
    );
  }

  /// Compact one-line hint of who this Person is. Deliberately avoids age
  /// math and other framing we haven't explicitly agreed to.
  String? _composeSubtitle(Person p) {
    final parts = <String>[];
    if (p.pronouns != null && p.pronouns!.trim().isNotEmpty) {
      parts.add(p.pronouns!.trim());
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No one here yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add anyone you want to keep track of — yourself, '
              "a kid, anyone you're supporting.",
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.personNew),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add someone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load People",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
