import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry_contract.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

/// Create or edit a profile entry for the active Person.
class ProfileEntryFormScreen extends ConsumerStatefulWidget {
  const ProfileEntryFormScreen({this.initialEntry, super.key});

  final ProfileEntry? initialEntry;

  bool get isEditing => initialEntry != null;

  @override
  ConsumerState<ProfileEntryFormScreen> createState() =>
      _ProfileEntryFormScreenState();
}

class _ProfileEntryFormScreenState
    extends ConsumerState<ProfileEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _details;
  late ProfileEntrySection _section;
  late ProfileEntryStatus _status;
  String? _parentEntryId;
  DateTime? _firstNoted;
  DateTime? _lastNoted;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialEntry;
    _label = TextEditingController(text: seed?.label ?? '');
    _details = TextEditingController(text: seed?.details ?? '');
    _section = seed?.section ?? ProfileEntrySection.stim;
    _status = seed?.status ?? ProfileEntryStatus.active;
    _parentEntryId = seed?.parentEntryId;
    _firstNoted = seed?.firstNoted;
    _lastNoted = seed?.lastNoted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_validateSeededParentLink());
    });
  }

  Future<void> _validateSeededParentLink() async {
    final seed = widget.initialEntry;
    if (seed == null) return;
    if (seed.section != ProfileEntrySection.routineStep) return;
    final pid = seed.parentEntryId;
    if (pid == null) return;
    final parent =
        await ref.read(profileEntryRepositoryProvider).findById(pid);
    if (!mounted) return;
    if (parent == null ||
        parent.deletedAt != null ||
        parent.section != ProfileEntrySection.routineBlock) {
      setState(() => _parentEntryId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pick a routine block — the previous link is no longer '
            'available.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _details.dispose();
    super.dispose();
  }

  static String? _nullIfBlank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  /// Calendar day in local time, stored as UTC instant of local midnight.
  static DateTime? _storageDate(DateTime? picked) {
    if (picked == null) return null;
    return DateTime(picked.year, picked.month, picked.day).toUtc();
  }

  static bool _datesOrdered(DateTime? first, DateTime? last) {
    if (first == null || last == null) return true;
    final a = DateTime(first.year, first.month, first.day);
    final b = DateTime(last.year, last.month, last.day);
    return !a.isAfter(b);
  }

  Future<void> _pickDate({required bool firstNoted}) async {
    final initial = firstNoted
        ? (_firstNoted ?? _lastNoted ?? DateTime.now())
        : (_lastNoted ?? _firstNoted ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (firstNoted) {
        _firstNoted = _storageDate(picked);
      } else {
        _lastNoted = _storageDate(picked);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    if (!_datesOrdered(_firstNoted, _lastNoted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First noted should be on or before last noted.'),
        ),
      );
      return;
    }

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
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getOrCreateForPerson(personId);
      final entryRepo = ref.read(profileEntryRepositoryProvider);
      final details = _nullIfBlank(_details.text);

      if (_section == ProfileEntrySection.routineStep) {
        final blocks = await entryRepo.listForProfile(
          profileId: profile.id,
          personId: personId,
        );
        final blockRows = blocks
            .where((e) => e.section == ProfileEntrySection.routineBlock)
            .where((e) => e.id != widget.initialEntry?.id)
            .toList();
        if (blockRows.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Add at least one routine block before adding steps.',
              ),
            ),
          );
          return;
        }
        if (_parentEntryId == null ||
            !blockRows.any((b) => b.id == _parentEntryId)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Choose which routine block this step belongs to.'),
            ),
          );
          return;
        }
      }

      if (widget.initialEntry == null) {
        await entryRepo.create(
          profileId: profile.id,
          personId: personId,
          section: _section,
          label: _label.text.trim(),
          details: details,
          status: _status,
          parentEntryId: _parentEntryId,
          firstNoted: _firstNoted,
          lastNoted: _lastNoted,
        );
      } else {
        final cur = widget.initialEntry!;
        await entryRepo.update(
          cur.copyWith(
            section: _section,
            label: _label.text.trim(),
            details: details,
            status: _status,
            parentEntryId: _parentEntryId,
            firstNoted: _firstNoted,
            lastNoted: _lastNoted,
          ),
        );
      }
      invalidateProfileEntriesState(ref);
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
    final seed = widget.initialEntry;
    final title = widget.isEditing ? 'Edit entry' : 'Add profile entry';
    final dateFmt = DateFormat.yMMMd();

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
                DropdownButtonFormField<ProfileEntrySection>(
                  key: ValueKey(_section),
                  initialValue: _section,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in ProfileEntrySection.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(labelForProfileEntrySection(s)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _section = v;
                      if (v != ProfileEntrySection.routineStep) {
                        _parentEntryId = null;
                      }
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    guidanceForProfileEntrySection(_section),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_section == ProfileEntrySection.routineStep) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final async = ref.watch(
                        profileEntriesForActivePersonProvider,
                      );
                      return async.when(
                        loading: () => const LinearProgressIndicator(
                          minHeight: 2,
                        ),
                        error: (e, _) => Text('$e'),
                        data: (all) {
                          final blocks = all
                              .where(
                                (e) =>
                                    e.section ==
                                    ProfileEntrySection.routineBlock,
                              )
                              .where((e) => e.id != widget.initialEntry?.id)
                              .toList();
                          if (blocks.isEmpty) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Routine block',
                                border: OutlineInputBorder(),
                                errorText:
                                    'Add a routine block first, then add steps '
                                    'under it.',
                              ),
                              child: SizedBox.shrink(),
                            );
                          }
                          final validValue = _parentEntryId != null &&
                              blocks.any((b) => b.id == _parentEntryId);
                          return DropdownButtonFormField<String?>(
                            key: ValueKey(
                              '${_parentEntryId ?? 'nil'}-${blocks.length}',
                            ),
                            initialValue: validValue ? _parentEntryId : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Routine block',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                child: Text('Select a routine block'),
                              ),
                              for (final b in blocks)
                                DropdownMenuItem(
                                  value: b.id,
                                  child: Text(
                                    b.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (id) =>
                                setState(() => _parentEntryId = id),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Choose a routine block';
                              }
                              return null;
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _label,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a short label';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _details,
                  minLines: 3,
                  maxLines: 10,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: detailsFieldLabelForSection(_section),
                    helperText: detailsFieldHelperForSection(_section),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _OptionalDateTile(
                  label: 'First noted (optional)',
                  value: _firstNoted,
                  dateFmt: dateFmt,
                  onPick: () => _pickDate(firstNoted: true),
                  onClear: () => setState(() => _firstNoted = null),
                ),
                const SizedBox(height: 8),
                _OptionalDateTile(
                  label: 'Last noted (optional)',
                  value: _lastNoted,
                  dateFmt: dateFmt,
                  onPick: () => _pickDate(firstNoted: false),
                  onClear: () => setState(() => _lastNoted = null),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProfileEntryStatus>(
                  key: ValueKey(_status),
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in ProfileEntryStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(labelForProfileEntryStatus(s)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                if (seed != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      Routes.notesForProfileEntry(seed.id),
                    ),
                    icon: const Icon(Icons.notes_outlined),
                    label: const Text('Notes that link to this line'),
                  ),
                  const SizedBox(height: 32),
                  _ArchiveOrRestoreButton(entry: seed),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalDateTile extends StatelessWidget {
  const _OptionalDateTile({
    required this.label,
    required this.value,
    required this.dateFmt,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat dateFmt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = value == null
        ? 'Not set'
        : dateFmt.format(value!.toLocal());

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
            IconButton(
              tooltip: 'Pick date',
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.entry});

  final ProfileEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = entry.deletedAt != null;
    final scheme = Theme.of(context).colorScheme;

    if (isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore entry'),
        onPressed: () => _restore(context, ref),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive entry',
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
        title: const Text('Archive this entry?'),
        content: const Text(
          'Archived entries disappear from the profile list. You can '
          'restore them from the edit screen while the link still works.',
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
      await ref.read(profileEntryRepositoryProvider).archive(entry.id);
      invalidateProfileEntriesState(ref);
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
      await ref.read(profileEntryRepositoryProvider).restore(entry.id);
      invalidateProfileEntriesState(ref);
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
