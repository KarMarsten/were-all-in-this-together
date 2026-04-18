import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_avatar.dart';

/// Bottom sheet that lets the user switch the active Person or jump into
/// the full People management screen.
///
/// Deliberately not a "picker" that blocks the app on first launch: if the
/// roster is empty, the sheet shows a gentle CTA to add someone, but we
/// never trap the user here.
Future<void> showPersonSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => const _PersonSwitcherSheetBody(),
  );
}

class _PersonSwitcherSheetBody extends ConsumerWidget {
  const _PersonSwitcherSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleListProvider);
    final activeIdAsync = ref.watch(activePersonIdProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Switch person',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            peopleAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(err.toString()),
              ),
              data: (people) {
                if (people.isEmpty) {
                  return const _SheetEmptyState();
                }
                final activeId = activeIdAsync.value;
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: people.length,
                    itemBuilder: (context, i) => _PersonRow(
                      person: people[i],
                      isActive: people[i].id == activeId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.people_outline),
              label: const Text('Manage people'),
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(context.push(Routes.people));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.person, required this.isActive});

  final Person person;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: PersonAvatar(person: person),
      title: Text(person.displayName),
      subtitle: person.pronouns == null || person.pronouns!.trim().isEmpty
          ? null
          : Text(person.pronouns!.trim()),
      trailing: isActive
          ? Icon(Icons.check_circle, color: scheme.primary)
          : null,
      selected: isActive,
      onTap: () async {
        await ref.read(activePersonIdProvider.notifier).select(person.id);
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No one added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add someone to start tracking.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(context.push(Routes.personNew));
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add someone'),
          ),
        ],
      ),
    );
  }
}
