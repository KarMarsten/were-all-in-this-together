import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
import 'package:were_all_in_this_together/features/observations/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Dated "Notes" timeline for the active Person (architecture: Observation).
class ObservationsListScreen extends ConsumerWidget {
  const ObservationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePersonAsync = ref.watch(activePersonProvider);
    final listAsync = ref.watch(activeObservationsProvider);
    final archivedAsync = ref.watch(archivedObservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        bottom: activePersonAsync.maybeWhen(
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
      floatingActionButton: activePersonAsync.maybeWhen(
        data: (person) => person == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.noteNew),
                icon: const Icon(Icons.add),
                label: const Text('Add note'),
              ),
        orElse: () => null,
      ),
      body: activePersonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (person) {
          if (person == null) return const _NoActivePersonState();
          return listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (active) {
              final archived = archivedAsync.value ?? const <Observation>[];
              if (active.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              final fmt = DateFormat('yMMMd · jm');
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  if (active.isNotEmpty)
                    for (final o in active)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _toneForCategory(
                            o.category,
                            context,
                          ).background,
                          foregroundColor: _toneForCategory(
                            o.category,
                            context,
                          ).foreground,
                          child: Icon(
                            _toneForCategory(o.category, context).icon,
                            size: 20,
                          ),
                        ),
                        title: Text(o.label),
                        subtitle: Text(
                          _subtitleForObservation(o, fmt),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(Routes.noteEdit(o.id)),
                      )
                  else
                    const _HistoryPlaceholder(),
                  if (archived.isNotEmpty)
                    _ArchivedSection(observations: archived, dateFmt: fmt),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _subtitleForObservation(Observation o, DateFormat fmt) {
  final parts = <String>[
    labelForObservationCategory(o.category),
    fmt.format(o.observedAt.toLocal()),
  ];
  if (o.profileEntryId != null) {
    parts.add('Linked to profile');
  }
  if (o.tags.isNotEmpty) {
    parts.add(o.tags.take(3).join(', '));
  }
  return parts.join(' · ');
}

class _CategoryTone {
  const _CategoryTone({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

_CategoryTone _toneForCategory(ObservationCategory c, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  switch (c) {
    case ObservationCategory.general:
      return _CategoryTone(
        icon: Icons.notes_outlined,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      );
    case ObservationCategory.wellbeing:
      return _CategoryTone(
        icon: Icons.self_improvement_outlined,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case ObservationCategory.sensory:
      return _CategoryTone(
        icon: Icons.touch_app_outlined,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      );
    case ObservationCategory.regulation:
      return _CategoryTone(
        icon: Icons.air_outlined,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    case ObservationCategory.school:
      return _CategoryTone(
        icon: Icons.school_outlined,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case ObservationCategory.health:
      return _CategoryTone(
        icon: Icons.favorite_outline,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    case ObservationCategory.other:
      return _CategoryTone(
        icon: Icons.label_outline,
        background: scheme.surfaceContainerHigh,
        foreground: scheme.onSurfaceVariant,
      );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({
    required this.observations,
    required this.dateFmt,
  });

  final List<Observation> observations;
  final DateFormat dateFmt;

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
          title: Text('Archived (${observations.length})'),
          children: [
            for (final o in observations)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _toneForCategory(
                    o.category,
                    context,
                  ).background,
                  foregroundColor: _toneForCategory(
                    o.category,
                    context,
                  ).foreground,
                  child: Icon(
                    _toneForCategory(o.category, context).icon,
                    size: 20,
                  ),
                ),
                title: Text(o.label),
                subtitle: Text(_subtitleForObservation(o, dateFmt)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.noteEdit(o.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIMELINE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing logged yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActivePersonState extends StatelessWidget {
  const _NoActivePersonState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Add someone to the roster first — notes are kept per person.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
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
              Icons.sticky_note_2_outlined,
              size: 56,
              color: scheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Short observations over time — sensory shifts, wins, '
              'patterns you notice day to day. Optional link to a profile '
              'line.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.noteNew),
              icon: const Icon(Icons.add),
              label: const Text('Add note'),
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
              "Couldn't load notes",
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
