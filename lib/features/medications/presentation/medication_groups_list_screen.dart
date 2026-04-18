import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Medication groups list for the currently-active Person.
///
/// Mirrors `MedicationsListScreen`'s layout — active rows on top,
/// archived collapsed at the bottom — so the mental model transfers
/// between the two screens.
class MedicationGroupsListScreen extends ConsumerWidget {
  const MedicationGroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activePersonProvider);
    final groupsAsync = ref.watch(medicationGroupsListProvider);
    final archivedAsync = ref.watch(archivedMedicationGroupsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication groups'),
        bottom: activeAsync.maybeWhen(
          data: (person) => person == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'for ${person.displayName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
          orElse: () => null,
        ),
      ),
      floatingActionButton: activeAsync.maybeWhen(
        data: (person) => person == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.medicationGroupNew),
                icon: const Icon(Icons.add),
                label: const Text('New group'),
              ),
        orElse: () => null,
      ),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (person) {
          if (person == null) {
            return const _NoActivePersonState();
          }
          return groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (groups) {
              final archived =
                  archivedAsync.value ?? const <MedicationGroup>[];
              if (groups.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  for (final g in groups) _GroupTile(group: g),
                  if (archived.isNotEmpty)
                    _ArchivedSection(groups: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final MedicationGroup group;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: const Icon(Icons.layers_outlined),
        title: Text(group.name),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.medicationGroupEdit(group.id)),
      ),
    );
  }

  String? _subtitle(BuildContext context) {
    final parts = <String>[];
    final n = group.memberMedicationIds.length;
    parts.add('$n ${n == 1 ? 'med' : 'meds'}');
    final scheduleHint = medicationScheduleLabel(context, group.schedule);
    if (scheduleHint != null) parts.add(scheduleHint);
    return parts.join(' · ');
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.groups});

  final List<MedicationGroup> groups;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text('Archived (${groups.length})'),
          children: [
            for (final g in groups)
              ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(g.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(Routes.medicationGroupEdit(g.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoActivePersonState extends StatelessWidget {
  const _NoActivePersonState();

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
              Icons.person_add_alt_1,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Add someone first',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Groups are kept per person, so we need to know who '
              "we're tracking them for.",
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
              Icons.layers_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bundle medications that are taken together — one reminder '
              'and one Taken tap for the whole stack.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.medicationGroupNew),
              icon: const Icon(Icons.add),
              label: const Text('New group'),
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
              "Couldn't load groups",
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
