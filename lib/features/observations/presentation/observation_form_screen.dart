import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:were_all_in_this_together/features/observations/data/observation_repository.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
import 'package:were_all_in_this_together/features/observations/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

/// Create or edit a dated note (Observation) for the active Person.
class ObservationFormScreen extends ConsumerStatefulWidget {
  const ObservationFormScreen({this.initialObservation, super.key});

  final Observation? initialObservation;

  bool get isEditing => initialObservation != null;

  @override
  ConsumerState<ObservationFormScreen> createState() =>
      _ObservationFormScreenState();
}

class _ObservationFormScreenState extends ConsumerState<ObservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  late ObservationCategory _category;
  late DateTime _observedAt;
  String? _profileEntryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialObservation;
    _label = TextEditingController(text: seed?.label ?? '');
    _notes = TextEditingController(text: seed?.notes ?? '');
    _tags = TextEditingController(text: seed?.tags.join(', ') ?? '');
    _category = seed?.category ?? ObservationCategory.general;
    _observedAt = seed?.observedAt.toUtc() ?? DateTime.now().toUtc();
    _profileEntryId = seed?.profileEntryId;
  }

  @override
  void dispose() {
    _label.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  static String? _nullIfBlank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _pickObservedAt() async {
    final local = _observedAt.toLocal();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(local.year, local.month, local.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (t == null || !mounted) return;
    final combined = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _observedAt = combined.toUtc());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final personId = await ref.read(activePersonIdProvider.future);
      if (personId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active person selected.')),
        );
        return;
      }
      final repo = ref.read(observationRepositoryProvider);
      final tags = _parseTags(_tags.text);
      final notes = _nullIfBlank(_notes.text);

      if (widget.initialObservation == null) {
        await repo.create(
          personId: personId,
          observedAt: _observedAt,
          category: _category,
          label: _label.text.trim(),
          notes: notes,
          tags: tags,
          profileEntryId: _profileEntryId,
        );
      } else {
        final cur = widget.initialObservation!;
        await repo.update(
          cur.copyWith(
            observedAt: _observedAt,
            category: _category,
            label: _label.text.trim(),
            notes: notes,
            tags: tags,
            profileEntryId: _profileEntryId,
          ),
        );
      }
      invalidateObservationsState(ref);
      if (!mounted) return;
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = widget.initialObservation;
    final title = widget.isEditing ? 'Edit note' : 'Add note';
    final whenFmt = DateFormat('yMMMd · jm');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('When'),
                  subtitle: Text(whenFmt.format(_observedAt.toLocal())),
                  trailing: IconButton(
                    tooltip: 'Change date & time',
                    icon: const Icon(Icons.edit_calendar_outlined),
                    onPressed: _pickObservedAt,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ObservationCategory>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in ObservationCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(labelForObservationCategory(c)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _label,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please add a short title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 10,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Body (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (optional, comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final async = ref.watch(activeProfileEntriesProvider);
                    return async.when(
                      loading: () => const LinearProgressIndicator(
                        minHeight: 2,
                      ),
                      error: (e, _) => Text('$e'),
                      data: (entries) {
                        if (entries.isEmpty) {
                          return const InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Link to profile line (optional)',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Add structured profile entries first to '
                                  'link one here.',
                            ),
                            child: SizedBox.shrink(),
                          );
                        }
                        final valid =
                            _profileEntryId != null &&
                            entries.any((e) => e.id == _profileEntryId);
                        return DropdownButtonFormField<String?>(
                          key: ValueKey(
                            '${_profileEntryId ?? 'nil'}-${entries.length}',
                          ),
                          initialValue: valid ? _profileEntryId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Link to profile line (optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              child: Text('None'),
                            ),
                            for (final e in entries)
                              DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  '${e.label} '
                                  '(${labelForProfileEntrySection(e.section)})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (id) =>
                              setState(() => _profileEntryId = id),
                        );
                      },
                    );
                  },
                ),
                if (seed != null) ...[
                  const SizedBox(height: 32),
                  _ArchiveOrRestoreButton(observation: seed),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = observation.deletedAt != null;
    final scheme = Theme.of(context).colorScheme;

    if (isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore note'),
        onPressed: () => _restore(context, ref),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive note',
        style: TextStyle(color: scheme.error),
      ),
      onPressed: () => _confirmAndArchive(context, ref),
    );
  }

  Future<void> _confirmAndArchive(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive this note?'),
        content: const Text(
          'Archived notes disappear from the main list. You can restore '
          'from the edit screen while the link still works.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(observationRepositoryProvider).archive(observation.id);
      invalidateObservationsState(ref);
      messenger.showSnackBar(const SnackBar(content: Text('Archived')));
      if (!context.mounted) return;
      context.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't archive: $e")),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(observationRepositoryProvider).restore(observation.id);
      invalidateObservationsState(ref);
      messenger.showSnackBar(const SnackBar(content: Text('Restored')));
      if (!context.mounted) return;
      context.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't restore: $e")),
      );
    }
  }
}
