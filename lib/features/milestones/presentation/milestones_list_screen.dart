import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/milestones/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Milestones list for the currently-active Person.
///
/// Three top-level states (mirrors the Appointments list screen):
/// * No active Person → point at "Add someone" first.
/// * Active Person, no milestones → friendly empty state.
/// * Normal list, reverse-chronological, grouped by year. Archived
///   milestones live in their own collapsible section below.
///
/// Year headers (rather than month or "Today") match the actual
/// shape of this data — some people log one thing a year, some log
/// five in a month. Grouping by month would be a lot of noise the
/// first time, grouping by "Today / This week" would rarely
/// match anything.
class MilestonesListScreen extends ConsumerWidget {
  const MilestonesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activePersonProvider);
    final listAsync = ref.watch(activeMilestonesProvider);
    final archivedAsync = ref.watch(archivedMilestonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestones & dates'),
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
                onPressed: () => context.push(Routes.milestoneNew),
                icon: const Icon(Icons.add),
                label: const Text('Add milestone'),
              ),
        orElse: () => null,
      ),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (person) {
          if (person == null) return const _NoActivePersonState();
          return listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (active) {
              final archived = archivedAsync.value ?? const <Milestone>[];
              if (active.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  if (active.isNotEmpty)
                    ..._buildYearGroupedSection(active)
                  else
                    const _HistoryPlaceholder(),
                  if (archived.isNotEmpty)
                    _ArchivedSection(milestones: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the active list as year-grouped tiles.
  ///
  /// Input is already sorted desc by `occurredAt`; this walks the
  /// list inserting a year header whenever the year changes,
  /// preserving order within each group.
  List<Widget> _buildYearGroupedSection(List<Milestone> milestones) {
    final widgets = <Widget>[];
    int? currentYear;
    for (final m in milestones) {
      final year = m.occurredAt.toUtc().year;
      if (currentYear != year) {
        widgets.add(_YearHeader(year: year));
        currentYear = year;
      }
      widgets.add(_MilestoneTile(milestone: m));
    }
    return widgets;
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$year',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = _visualsForKind(milestone.kind, scheme);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visuals.background,
          foregroundColor: visuals.foreground,
          child: Icon(visuals.icon),
        ),
        title: Text(milestone.title),
        subtitle: Text(
          '${formatMilestoneDate(milestone)} · ${labelForKind(milestone.kind)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.milestoneEdit(milestone.id)),
      ),
    );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.milestones});

  final List<Milestone> milestones;

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
          title: Text('Archived (${milestones.length})'),
          children: [
            for (final m in milestones)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.surfaceContainerHigh,
                  foregroundColor: scheme.onSurfaceVariant,
                  child: Icon(_visualsForKind(m.kind, scheme).icon),
                ),
                title: Text(m.title),
                subtitle: Text(
                  '${formatMilestoneDate(m)} · ${labelForKind(m.kind)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.milestoneEdit(m.id)),
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
            'HISTORY',
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
              'Milestones are kept per person, so we need to know who '
              "we're logging them for.",
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
              Icons.history_edu_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No milestones yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Diagnoses, shots, developmental firsts, moves — the dated '
              "events you'll want to remember.",
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.milestoneNew),
              icon: const Icon(Icons.add),
              label: const Text('Add milestone'),
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
              "Couldn't load milestones",
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

/// Human label for a [MilestoneKind]. Exposed so the form screen
/// and widget tests can reuse it without reaching into private
/// state.
String labelForKind(MilestoneKind k) {
  switch (k) {
    case MilestoneKind.diagnosis:
      return 'Diagnosis';
    case MilestoneKind.vaccine:
      return 'Vaccine';
    case MilestoneKind.development:
      return 'Development';
    case MilestoneKind.health:
      return 'Health';
    case MilestoneKind.life:
      return 'Life event';
    case MilestoneKind.other:
      return 'Other';
  }
}

/// Icon + avatar colours for a [MilestoneKind].
///
/// Uses the Material colour scheme's "container" tints so the
/// palette stays on-brand in both light and dark themes without
/// hard-coded colours.
_KindVisuals _visualsForKind(MilestoneKind k, ColorScheme scheme) {
  switch (k) {
    case MilestoneKind.diagnosis:
      return _KindVisuals(
        icon: Icons.assignment_outlined,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    case MilestoneKind.vaccine:
      return _KindVisuals(
        icon: Icons.vaccines_outlined,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case MilestoneKind.development:
      return _KindVisuals(
        icon: Icons.child_care_outlined,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      );
    case MilestoneKind.health:
      return _KindVisuals(
        icon: Icons.healing_outlined,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    case MilestoneKind.life:
      return _KindVisuals(
        icon: Icons.flag_outlined,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case MilestoneKind.other:
      return _KindVisuals(
        icon: Icons.label_outline,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      );
  }
}

class _KindVisuals {
  const _KindVisuals({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}
