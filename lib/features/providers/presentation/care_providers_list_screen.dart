import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Care providers list for the currently-active Person.
///
/// Three top-level states:
/// * No active Person → point at "Add someone" first, since a provider
///   without an owner can't exist in the Phase 1 per-Person model.
/// * Active Person but no providers → friendly empty state.
/// * Normal list grouped by kind (PCP first, then the other buckets in
///   enum order), with an expandable "Archived" section below.
class CareProvidersListScreen extends ConsumerWidget {
  const CareProvidersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activePersonProvider);
    final providersAsync = ref.watch(careProvidersListProvider);
    final archivedAsync = ref.watch(archivedCareProvidersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers'),
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
                onPressed: () => context.push(Routes.careProviderNew),
                icon: const Icon(Icons.add),
                label: const Text('Add provider'),
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
          return providersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (providers) {
              final archived =
                  archivedAsync.value ?? const <CareProvider>[];
              if (providers.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  ..._buildKindGroups(providers),
                  if (archived.isNotEmpty)
                    _ArchivedSection(providers: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Groups active providers by kind, emitting header + tiles per
  /// non-empty kind. Kinds render in enum order so PCPs lead — matching
  /// how most people mentally list "our doctors".
  List<Widget> _buildKindGroups(List<CareProvider> providers) {
    final widgets = <Widget>[];
    for (final kind in CareProviderKind.values) {
      final group = providers.where((p) => p.kind == kind).toList();
      if (group.isEmpty) continue;
      widgets
        ..add(_KindHeader(kind: kind, count: group.length))
        ..addAll(group.map((p) => _CareProviderTile(provider: p)));
    }
    return widgets;
  }
}

/// Small label that introduces a group of providers of the same kind.
class _KindHeader extends StatelessWidget {
  const _KindHeader({required this.kind, required this.count});

  final CareProviderKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(iconForKind(kind), size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            labelForKind(kind),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _CareProviderTile extends StatelessWidget {
  const _CareProviderTile({required this.provider});

  final CareProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          foregroundColor:
              Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(iconForKind(provider.kind)),
        ),
        title: Text(provider.name),
        subtitle: _subtitleFor(provider) == null
            ? null
            : Text(_subtitleFor(provider)!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.careProviderDetail(provider.id)),
      ),
    );
  }

  /// Specialty / role / contact / phone, whichever the user filled in.
  /// The identifying relationship leads; contact details trail.
  String? _subtitleFor(CareProvider p) {
    final parts = <String>[];
    final specialty = p.specialty?.trim();
    if (specialty != null && specialty.isNotEmpty) {
      parts.add(specialty);
    }
    final role = p.role?.trim();
    if (role != null && role.isNotEmpty) {
      parts.add(role);
    }
    final contact = p.contactName?.trim();
    if (contact != null && contact.isNotEmpty) {
      parts.add(contact);
    }
    final phone = p.phone?.trim();
    if (phone != null && phone.isNotEmpty) {
      parts.add(phone);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Collapsible "Archived" group rendered at the bottom of the list.
class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.providers});

  final List<CareProvider> providers;

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
          title: Text('Archived (${providers.length})'),
          children: [
            for (final p in providers)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.surfaceContainerHigh,
                  foregroundColor: scheme.onSurfaceVariant,
                  child: Icon(iconForKind(p.kind)),
                ),
                title: Text(p.name),
                subtitle: p.specialty == null || p.specialty!.trim().isEmpty
                    ? null
                    : Text(p.specialty!.trim()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(Routes.careProviderDetail(p.id)),
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
              'Providers are kept per person, so we need to know who '
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
              Icons.local_hospital_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No providers yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Add the people on this Person's care team — PCPs, "
              'specialists, therapists, dentists, anyone you keep '
              'coming back to.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.careProviderNew),
              icon: const Icon(Icons.add),
              label: const Text('Add provider'),
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
              "Couldn't load providers",
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

/// User-facing label for a [CareProviderKind]. Kept outside the enum so
/// it's easy to later swap in localised strings without touching the
/// wire-name serialisation.
String labelForKind(CareProviderKind kind) => switch (kind) {
      CareProviderKind.pcp => 'Primary care',
      CareProviderKind.specialist => 'Specialists',
      CareProviderKind.therapist => 'Therapists',
      CareProviderKind.dentist => 'Dental',
      CareProviderKind.other => 'Other',
    };

/// Icon used in tile leading avatars and kind headers. Chosen to be
/// recognisable at small sizes without relying on colour alone.
IconData iconForKind(CareProviderKind kind) => switch (kind) {
      CareProviderKind.pcp => Icons.medical_services_outlined,
      CareProviderKind.specialist => Icons.local_hospital_outlined,
      CareProviderKind.therapist => Icons.psychology_outlined,
      CareProviderKind.dentist => Icons.masks_outlined,
      CareProviderKind.other => Icons.person_outline,
    };
