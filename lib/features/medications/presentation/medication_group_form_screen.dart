import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_icon.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Form for creating or editing a [MedicationGroup].
///
/// Semantics (parallel to `MedicationFormScreen`):
///
/// * Create mode binds the new group to the active Person at submit.
/// * Edit mode preserves `personId`; ownership transfer is not
///   supported (groups are Person-scoped and moving them would imply
///   re-encryption under a different key).
/// * Member picker only shows active, active-Person meds — cross-Person
///   membership is disallowed because keys differ per Person.
/// * Archive / Restore live on the edit screen, mirroring the
///   medication form.
class MedicationGroupFormScreen extends ConsumerStatefulWidget {
  const MedicationGroupFormScreen({this.initialGroup, super.key});

  final MedicationGroup? initialGroup;

  bool get isEditing => initialGroup != null;

  @override
  ConsumerState<MedicationGroupFormScreen> createState() =>
      _MedicationGroupFormScreenState();
}

class _MedicationGroupFormScreenState
    extends ConsumerState<MedicationGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  MedicationSchedule _schedule = MedicationSchedule.asNeeded;
  final Set<String> _memberIds = <String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialGroup;
    _name = TextEditingController(text: seed?.name ?? '');
    _schedule = seed?.schedule ?? MedicationSchedule.asNeeded;
    if (seed != null) {
      _memberIds.addAll(seed.memberMedicationIds);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialGroup!.name}'
        : 'Add group';
    final medsAsync = ref.watch(medicationsListProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
                TextFormField(
                  controller: _name,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    helperText:
                        'What you call this bundle — "Morning stack", '
                        '"Before bed", etc.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                MedicationScheduleEditor(
                  value: _schedule,
                  onChanged: (s) => setState(() => _schedule = s),
                ),
                const SizedBox(height: 24),
                Text('Medications in this group', style: text.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Tap Taken on the group and we log every med in it at '
                  'that time. Meds stay independent — this is just a '
                  'bundle.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                medsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Couldn't load medications: $err"),
                  ),
                  data: (meds) => _MembersPicker(
                    meds: meds,
                    selected: _memberIds,
                    onToggle: (id, {required on}) {
                      setState(() {
                        if (on) {
                          _memberIds.add(id);
                        } else {
                          _memberIds.remove(id);
                        }
                      });
                    },
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ArchiveOrRestoreButton(group: widget.initialGroup!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.isEditing) {
        final repo = ref.read(medicationGroupRepositoryProvider);
        await repo.update(
          widget.initialGroup!.copyWith(
            name: _name.text.trim(),
            schedule: _schedule,
            memberMedicationIds: _memberIds.toList(),
          ),
        );
      } else {
        final personId = await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Add a person first before creating a group.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final repo = ref.read(medicationGroupRepositoryProvider);
        await repo.create(
          personId: personId,
          name: _name.text.trim(),
          schedule: _schedule,
          memberMedicationIds: _memberIds.toList(),
        );
      }
      invalidateGroupsState(ref);
      if (!mounted) return;
      context.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't save: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Checkbox list of the active Person's medications. Pure UI — state
/// is owned by the enclosing form so selection survives a schedule
/// edit without the picker needing its own store.
class _MembersPicker extends StatelessWidget {
  const _MembersPicker({
    required this.meds,
    required this.selected,
    required this.onToggle,
  });

  final List<Medication> meds;
  final Set<String> selected;
  final void Function(String id, {required bool on}) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (meds.isEmpty) {
      return Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No medications to pick from yet. Add medications first, '
            'then come back to bundle them.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
            for (final m in meds)
            CheckboxListTile(
              value: selected.contains(m.id),
              onChanged: (v) => onToggle(m.id, on: v ?? false),
              secondary: MedicationIcon(form: m.form),
              title: Text(m.name),
              subtitle: m.dose == null || m.dose!.trim().isEmpty
                  ? null
                  : Text(m.dose!.trim()),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
        ],
      ),
    );
  }
}

/// Archive / Restore affordance at the bottom of the edit form, the
/// same shape as the medication form's corresponding widget.
class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.group});

  final MedicationGroup group;

  bool get _isArchived => group.deletedAt != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (_isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore group'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _restore(context, ref),
      );
    }
    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive group',
        style: TextStyle(color: scheme.error),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _archive(context, ref),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive ${group.name}?'),
        content: const Text(
          'The individual medications stay put — only the bundle is '
          'archived. Restore at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final repo = ref.read(medicationGroupRepositoryProvider);
    try {
      await repo.archive(group.id);
      invalidateGroupsState(ref);
      if (!context.mounted) return;
      context.pop();
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't archive: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(medicationGroupRepositoryProvider);
    try {
      await repo.restore(group.id);
      invalidateGroupsState(ref);
      if (!context.mounted) return;
      context.pop();
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't restore: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
