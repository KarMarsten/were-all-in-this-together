import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';

/// Schools, camps, after-care — encrypted per active Person.
class ProgramsListScreen extends ConsumerWidget {
  const ProgramsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePerson = ref.watch(activePersonProvider);
    final listAsync = ref.watch(activeProgramsProvider);
    final archivedAsync = ref.watch(archivedProgramsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        bottom: activePerson.maybeWhen(
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
      floatingActionButton: activePerson.maybeWhen(
        data: (person) => person == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.programNew),
                icon: const Icon(Icons.add),
                label: const Text('Add program'),
              ),
        orElse: () => null,
      ),
      body: activePerson.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add someone to the roster first — programs are kept per '
                  'person.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (active) {
              final archived = archivedAsync.value ?? const <Program>[];
              if (active.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  ..._kindGroups(context, active),
                  if (archived.isNotEmpty)
                    _ArchivedSection(programs: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static List<Widget> _kindGroups(BuildContext context, List<Program> all) {
    final out = <Widget>[];
    for (final kind in ProgramKind.values) {
      final group = all.where((p) => p.kind == kind).toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      if (group.isEmpty) continue;
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(
            labelForProgramKind(kind),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
      for (final p in group) {
        final parts = <String>[
          if (p.phone != null && p.phone!.trim().isNotEmpty) p.phone!,
          if (p.notes != null && p.notes!.trim().isNotEmpty) p.notes!.trim(),
        ];
        out.add(
          ListTile(
            title: Text(p.name),
            subtitle: Text(
              parts.isEmpty ? 'Tap to edit' : parts.join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.programEdit(p.id)),
          ),
        );
      }
    }
    return out;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No programs yet. Add a school, camp, or after-care contact — '
          'phone numbers are encrypted with the rest.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.programs});

  final List<Program> programs;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Archived (${programs.length})'),
      children: [
        for (final p in programs)
          ListTile(
            title: Text(p.name),
            subtitle: Text(labelForProgramKind(p.kind)),
            onTap: () => context.push(Routes.programEdit(p.id)),
          ),
      ],
    );
  }
}
