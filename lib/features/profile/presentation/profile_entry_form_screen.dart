import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

/// Create or edit a [ProfileEntry] for the active Person.
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialEntry;
    _label = TextEditingController(text: seed?.label ?? '');
    _details = TextEditingController(text: seed?.details ?? '');
    _section = seed?.section ?? ProfileEntrySection.stim;
    _status = seed?.status ?? ProfileEntryStatus.active;
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
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getOrCreateForPerson(personId);
      final entryRepo = ref.read(profileEntryRepositoryProvider);
      final details = _nullIfBlank(_details.text);

      if (widget.initialEntry == null) {
        await entryRepo.create(
          profileId: profile.id,
          personId: personId,
          section: _section,
          label: _label.text.trim(),
          details: details,
          status: _status,
        );
      } else {
        final cur = widget.initialEntry!;
        await entryRepo.update(
          cur.copyWith(
            section: _section,
            label: _label.text.trim(),
            details: details,
            status: _status,
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
                    if (v != null) setState(() => _section = v);
                  },
                ),
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
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    border: OutlineInputBorder(),
                  ),
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
