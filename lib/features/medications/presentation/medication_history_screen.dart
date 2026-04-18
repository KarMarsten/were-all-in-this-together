import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Reverse-chron timeline of a medication's regimen changes.
///
/// Events are written automatically by `MedicationRepository` on
/// create / update / archive / restore, and (in a later PR) by the
/// user manually backfilling past changes. This screen is read-only
/// in its first iteration — the goal is "caregivers and clinicians
/// can see how the regimen has evolved over time" rather than "edit
/// the timeline".
class MedicationHistoryScreen extends ConsumerWidget {
  const MedicationHistoryScreen({required this.medicationId, super.key});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(medicationHistoryProvider(medicationId));
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (events) => events.isEmpty
            ? const _EmptyState()
            : _HistoryList(events: events),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(Routes.medicationHistoryNew(medicationId)),
        icon: const Icon(Icons.add),
        label: const Text('Add note'),
      ),
    );
  }
}

/// Stateful because of swipe-to-archive. The interaction needs a
/// local "dismissed" set so that `Dismissible.onDismissed` returns
/// to a tree where the widget is actually gone on the very next
/// frame — relying on the Riverpod `FutureProvider` to re-emit
/// would leave Flutter asserting "a dismissed Dismissible is still
/// part of the tree" because the provider reload is async.
class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({required this.events});

  final List<MedicationEvent> events;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  final _locallyArchived = <String>{};

  @override
  Widget build(BuildContext context) {
    final visible = widget.events
        .where((e) => !_locallyArchived.contains(e.id))
        .toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _DismissibleEvent(
        event: visible[index],
        onConfirmedArchive: _handleArchive,
      ),
    );
  }

  Future<void> _handleArchive(MedicationEvent event) async {
    // Optimistic UI: drop the row now, undo if the repo write fails.
    setState(() => _locallyArchived.add(event.id));
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(medicationEventRepositoryProvider);
    try {
      await repo.archive(event.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _locallyArchived.remove(event.id));
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't remove: $e")),
      );
      return;
    }
    if (!mounted) return;
    // Provider reload will eventually arrive with the archived row
    // excluded. Once it does the local set is harmless — events
    // only ever come in via the provider, and archived rows aren't
    // returned.
    ref.invalidate(
      medicationHistoryProvider(event.medicationId),
    );
  }
}

/// Swipe-to-archive wrapper around [_EventTile].
///
/// Archiving (the event repo's soft-delete) is used to correct a
/// mis-logged event — the user typoed the date, meant to attach a
/// note to a different med, or wants to clean up auto-log noise.
/// A confirmation dialog prevents fat-fingered swipes from quietly
/// destroying history; archive under the hood is soft-delete, so
/// even a confirmed remove is recoverable at the data layer.
class _DismissibleEvent extends StatelessWidget {
  const _DismissibleEvent({
    required this.event,
    required this.onConfirmedArchive,
  });

  final MedicationEvent event;
  final Future<void> Function(MedicationEvent event) onConfirmedArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      // `confirmDismiss` treats a null/false result as "don't
      // dismiss", so we can return the dialog's Future<bool?>
      // directly — null (tapped outside) == Cancel.
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove this event?'),
          content: const Text(
            'It will disappear from the timeline. You can '
            'always add a new note if this was a mistake.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onConfirmedArchive(event),
      child: _EventTile(event: event),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});

  final MedicationEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final providersAsync =
        ref.watch(careProviderPickerProvider(event.personId));

    // Resolve any prescriberId diff values back to provider names so
    // the timeline reads "prescriber changed from Dr. Chen to Dr.
    // Ortiz" rather than raw UUIDs. We degrade to the UUID when the
    // picker can't find the id (e.g. key still loading, or the
    // provider was hard-deleted by a future migration). Archived
    // providers are intentionally resolvable here — that's exactly
    // the situation where keeping a human-readable label matters.
    String? resolveProvider(String? id) {
      if (id == null) return null;
      final data = providersAsync.maybeWhen(
        data: (d) => d,
        orElse: () => null,
      );
      final found = data?.byId(id);
      return found?.name;
    }

    return ListTile(
      leading: _iconFor(event.kind, theme),
      title: Text(
        _titleFor(event.kind, diffs: event.diffs.length),
        style: theme.textTheme.titleSmall,
      ),
      subtitle: _SubtitleBody(
        event: event,
        resolveProvider: resolveProvider,
      ),
      trailing: Text(
        _formatOccurredAt(event.occurredAt),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      ),
      isThreeLine: event.diffs.isNotEmpty || event.note != null,
    );
  }
}

class _SubtitleBody extends StatelessWidget {
  const _SubtitleBody({required this.event, required this.resolveProvider});

  final MedicationEvent event;
  final String? Function(String? id) resolveProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (final diff in event.diffs) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _describeDiff(diff, resolveProvider: resolveProvider),
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    if (event.note != null && event.note!.trim().isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            event.note!.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

Icon _iconFor(MedicationEventKind kind, ThemeData theme) {
  final color = theme.colorScheme.primary;
  switch (kind) {
    case MedicationEventKind.created:
      return Icon(Icons.add_circle_outline, color: color);
    case MedicationEventKind.fieldsChanged:
      return Icon(Icons.edit_note, color: color);
    case MedicationEventKind.archived:
      return Icon(Icons.archive_outlined, color: theme.colorScheme.outline);
    case MedicationEventKind.restored:
      return Icon(Icons.unarchive_outlined, color: color);
    case MedicationEventKind.note:
      return Icon(Icons.sticky_note_2_outlined, color: color);
  }
}

String _titleFor(MedicationEventKind kind, {required int diffs}) {
  switch (kind) {
    case MedicationEventKind.created:
      return 'Added to this person';
    case MedicationEventKind.fieldsChanged:
      if (diffs == 1) return 'Updated 1 field';
      return 'Updated $diffs fields';
    case MedicationEventKind.archived:
      return 'Archived';
    case MedicationEventKind.restored:
      return 'Restored';
    case MedicationEventKind.note:
      return 'Note';
  }
}

/// Human-friendly rendering of one field diff. Intentionally
/// permissive: when a diff represents "set for the first time" or
/// "cleared", we pick prose that reads naturally instead of using
/// the literal word `null`.
String _describeDiff(
  MedicationFieldDiff diff, {
  required String? Function(String? id) resolveProvider,
}) {
  final label = _fieldLabel(diff.field);
  final prev = _renderValue(diff.field, diff.previous, resolveProvider);
  final curr = _renderValue(diff.field, diff.current, resolveProvider);
  if (prev == null && curr != null) return '$label set to $curr';
  if (prev != null && curr == null) return '$label cleared (was $prev)';
  return '$label: $prev → $curr';
}

/// UI copy for known field wire names. Unknown fields (e.g. from a
/// future build) fall through to the raw wire name so something still
/// renders.
String _fieldLabel(String wire) {
  switch (wire) {
    case 'name':
      return 'Name';
    case 'dose':
      return 'Dose';
    case 'form':
      return 'Form';
    case 'prescriber':
      return 'Prescriber note';
    case 'prescriberId':
      return 'Prescribed by';
    case 'startDate':
      return 'Start date';
    case 'endDate':
      return 'End date';
    case 'schedule':
      return 'Schedule';
  }
  return wire;
}

String? _renderValue(
  String field,
  String? raw,
  String? Function(String? id) resolveProvider,
) {
  if (raw == null) return null;
  if (field == 'prescriberId') {
    final resolved = resolveProvider(raw);
    return resolved ?? 'provider $raw';
  }
  return raw;
}

/// Date-only for events older than today; time-only for events
/// stamped today, so the recent edits read like a session log and
/// the older ones like a calendar. No year component — the screen's
/// title already tells the user "this is history of *this med*", and
/// tapping an event in a future PR will reveal the full timestamp.
String _formatOccurredAt(DateTime when) {
  final local = when.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isToday) {
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final y = local.year.toString().padLeft(4, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$mo-$d';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No history yet.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Changes you make to this medication will show up '
              'here so you can see how the regimen evolved.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
