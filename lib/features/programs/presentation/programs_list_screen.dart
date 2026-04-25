import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

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
        out.add(_ProgramTile(program: p));
      }
    }
    return out;
  }
}

class _ProgramTile extends ConsumerWidget {
  const _ProgramTile({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opener = ref.watch(urlOpenerProvider);
    final availableActions = <_ProgramAction>[
      if (_notBlank(program.phone)) _ProgramAction.call,
      if (_notBlank(program.email)) _ProgramAction.email,
      if (_notBlank(program.websiteUrl)) _ProgramAction.web,
      if (_notBlank(program.address)) _ProgramAction.map,
    ];
    final providerName = ref
        .watch(careProviderPickerProvider(program.personId))
        .maybeWhen(
          data: (providers) => providers.byId(program.providerId ?? '')?.name,
          orElse: () => null,
        );

    return ListTile(
      title: Text(program.name),
      subtitle: Text(_subtitle(program, providerName: providerName)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (availableActions.isNotEmpty)
            PopupMenuButton<_ProgramAction>(
              tooltip: 'Program actions',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => _handleAction(
                context: context,
                opener: opener,
                action: action,
              ),
              itemBuilder: (context) => [
                for (final action in availableActions)
                  PopupMenuItem(
                    value: action,
                    child: Text(_actionLabel(action)),
                  ),
              ],
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push(Routes.programEdit(program.id)),
    );
  }

  static bool _notBlank(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _subtitle(Program p, {String? providerName}) {
    final contact = [p.contactName, p.contactRole]
        .where(_notBlank)
        .map((s) => s!.trim())
        .join(', ');
    final parts = <String>[
      if (contact.isNotEmpty) contact,
      if (_notBlank(providerName)) 'Provider: ${providerName!.trim()}',
      if (_notBlank(p.hours)) p.hours!.trim(),
      if (_notBlank(p.phone)) p.phone!.trim(),
      if (_notBlank(p.email)) p.email!.trim(),
      if (_notBlank(p.address)) p.address!.trim(),
      if (_notBlank(p.notes)) p.notes!.trim(),
    ];
    return parts.isEmpty ? 'Tap to edit' : parts.join(' · ');
  }

  Future<void> _handleAction({
    required BuildContext context,
    required UrlOpener opener,
    required _ProgramAction action,
  }) {
    switch (action) {
      case _ProgramAction.call:
        return _open(
          context,
          () => opener.openTel(program.phone!),
          "Couldn't open phone",
        );
      case _ProgramAction.email:
        return _open(
          context,
          () => opener.openEmail(program.email!),
          "Couldn't open email",
        );
      case _ProgramAction.web:
        return _open(
          context,
          () => opener.openWeb(program.websiteUrl!),
          "Couldn't open website",
        );
      case _ProgramAction.map:
        return _open(
          context,
          () => opener.openMap(program.address!),
          "Couldn't open map",
        );
    }
  }

  static String _actionLabel(_ProgramAction action) {
    switch (action) {
      case _ProgramAction.call:
        return 'Call';
      case _ProgramAction.email:
        return 'Email';
      case _ProgramAction.web:
        return 'Open website';
      case _ProgramAction.map:
        return 'Open map';
    }
  }

  static Future<void> _open(
    BuildContext context,
    Future<bool> Function() action,
    String failureMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}

enum _ProgramAction { call, email, web, map }

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
