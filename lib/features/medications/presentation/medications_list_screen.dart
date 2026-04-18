import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_icon.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Medications list for the currently-active Person.
///
/// Three top-level states:
/// * No active Person at all (roster empty) → point at "Add someone" first,
///   because a med without an owner can't exist.
/// * Active Person but no meds → friendly empty state + "Add medication".
/// * Normal list with tiles + an expandable "Archived" section when there
///   are archived meds.
class MedicationsListScreen extends ConsumerWidget {
  const MedicationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activePersonProvider);
    final medsAsync = ref.watch(medicationsListProvider);
    final archivedAsync = ref.watch(archivedMedicationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
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
                onPressed: () => context.push(Routes.medicationNew),
                icon: const Icon(Icons.add),
                label: const Text('Add medication'),
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
          return medsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (meds) {
              final archived =
                  archivedAsync.value ?? const <Medication>[];
              if (meds.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  for (final m in meds) _MedicationTile(medication: m),
                  if (archived.isNotEmpty)
                    _ArchivedSection(medications: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: MedicationIcon(form: medication.form),
        title: Text(medication.name),
        subtitle: _subtitle() == null ? null : Text(_subtitle()!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.push(Routes.medicationEdit(medication.id)),
      ),
    );
  }

  /// Dose · form, trimmed to whatever is present. We skip framing like
  /// "at 8am" here — that belongs to the schedule PR, not the intrinsic
  /// medication record.
  String? _subtitle() {
    final parts = <String>[];
    if (medication.dose != null && medication.dose!.trim().isNotEmpty) {
      parts.add(medication.dose!.trim());
    }
    if (medication.form != null) {
      parts.add(medicationFormLabel(medication.form));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Collapsible "Archived" group rendered at the bottom of the list.
///
/// Archived meds belong in sight but out of the way — a long history of
/// "meds we used to take" is clinically useful but shouldn't dominate
/// the live view. Rendered as an [ExpansionTile] to keep the default
/// state tidy.
class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.medications});

  final List<Medication> medications;

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
          title: Text('Archived (${medications.length})'),
          children: [
            for (final m in medications)
              ListTile(
                leading: MedicationIcon(form: m.form),
                title: Text(m.name),
                subtitle: m.dose == null || m.dose!.trim().isEmpty
                    ? null
                    : Text(m.dose!.trim()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(Routes.medicationEdit(m.id)),
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
              'Medications are kept per person, so we need to know who '
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
              Icons.medication_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No medications yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Add one when you're ready — supplements, prescriptions, "
              'anything you want to keep track of.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.medicationNew),
              icon: const Icon(Icons.add),
              label: const Text('Add medication'),
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
              "Couldn't load medications",
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
