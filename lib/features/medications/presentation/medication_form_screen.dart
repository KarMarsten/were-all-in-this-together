import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_icon.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/reminder_override_editor.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart'
    show labelForKind;
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Form for creating or editing a [Medication].
///
/// Semantics:
///
/// * Create mode (`initialMedication == null`) binds the new medication
///   to whatever the active Person is at submit time.
/// * Edit mode preserves the stored `personId` — we never let the form
///   transfer ownership. If you need that, archive the current row and
///   create a new one under the other Person.
/// * Edit mode shows an "Archive" action at the bottom instead of a
///   destructive "Delete". If the medication is already archived, the
///   action becomes "Restore".
class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({this.initialMedication, super.key});

  final Medication? initialMedication;

  bool get isEditing => initialMedication != null;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _prescriber;
  late final TextEditingController _notes;
  MedicationForm? _form;
  String? _prescriberId;
  DateTime? _startDate;
  DateTime? _endDate;
  MedicationSchedule _schedule = MedicationSchedule.asNeeded;
  int? _nagIntervalOverride;
  int? _nagCapOverride;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialMedication;
    _name = TextEditingController(text: seed?.name ?? '');
    _dose = TextEditingController(text: seed?.dose ?? '');
    _prescriber = TextEditingController(text: seed?.prescriber ?? '');
    _notes = TextEditingController(text: seed?.notes ?? '');
    _form = seed?.form;
    _prescriberId = seed?.prescriberId;
    _startDate = seed?.startDate;
    _endDate = seed?.endDate;
    _schedule = seed?.schedule ?? MedicationSchedule.asNeeded;
    _nagIntervalOverride = seed?.nagIntervalMinutesOverride;
    _nagCapOverride = seed?.nagCapOverride;
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _prescriber.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialMedication!.name}'
        : 'Add medication';

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
                    helperText: 'Brand or generic — whatever you call it.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dose,
                  decoration: const InputDecoration(
                    labelText: 'Dose (optional)',
                    hintText: 'e.g. 10mg, half a tablet, 5ml',
                  ),
                ),
                const SizedBox(height: 16),
                _FormDropdown(
                  value: _form,
                  onChanged: (v) => setState(() => _form = v),
                ),
                const SizedBox(height: 16),
                // Resolve the picker's personId from the active Person
                // in create mode, or the medication's own Person in edit
                // mode (the form never moves a med between People).
                // When no Person is active yet the picker just hides —
                // the free-text prescriber below still works.
                _PrescriberPicker(
                  personId: widget.initialMedication?.personId ??
                      ref.watch(activePersonIdProvider).value,
                  value: _prescriberId,
                  onChanged: (v) => setState(() => _prescriberId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prescriber,
                  decoration: const InputDecoration(
                    labelText: 'Prescriber note (optional)',
                    hintText: 'Name or practice',
                    helperText:
                        "Use this when the prescriber isn't in your "
                        'Providers list (e.g. a one-off urgent-care visit).',
                  ),
                ),
                const SizedBox(height: 16),
                _DateRow(
                  label: 'Start date (optional)',
                  value: _startDate,
                  onChanged: (d) => setState(() => _startDate = d),
                ),
                const SizedBox(height: 12),
                _DateRow(
                  label: 'End date (optional)',
                  value: _endDate,
                  onChanged: (d) => setState(() => _endDate = d),
                  helpText: 'Leave empty if still taking',
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                MedicationScheduleEditor(
                  value: _schedule,
                  onChanged: (s) => setState(() => _schedule = s),
                ),
                const SizedBox(height: 24),
                ReminderOverrideEditor(
                  intervalMinutesOverride: _nagIntervalOverride,
                  capOverride: _nagCapOverride,
                  onIntervalChanged: (v) =>
                      setState(() => _nagIntervalOverride = v),
                  onCapChanged: (v) => setState(() => _nagCapOverride = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    helperText:
                        'Instructions, side effects to watch for, '
                        'things you want to remember.',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 8,
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ArchiveOrRestoreButton(
                    medication: widget.initialMedication!,
                  ),
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
        final repo = ref.read(medicationRepositoryProvider);
        await repo.update(
          widget.initialMedication!.copyWith(
            name: _name.text.trim(),
            dose: _nullIfBlank(_dose.text),
            form: _form,
            prescriber: _nullIfBlank(_prescriber.text),
            prescriberId: _prescriberId,
            notes: _nullIfBlank(_notes.text),
            startDate: _startDate,
            endDate: _endDate,
            schedule: _schedule,
            nagIntervalMinutesOverride: _nagIntervalOverride,
            nagCapOverride: _nagCapOverride,
          ),
        );
      } else {
        // Create binds to the active Person at submit time. Reading via
        // the AsyncNotifier's .future gives us a stable id even if the
        // UI is still loading when the user hits Save fast.
        final personId =
            await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Add a person first before creating a medication.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final repo = ref.read(medicationRepositoryProvider);
        await repo.create(
          personId: personId,
          name: _name.text.trim(),
          dose: _nullIfBlank(_dose.text),
          form: _form,
          prescriber: _nullIfBlank(_prescriber.text),
          prescriberId: _prescriberId,
          notes: _nullIfBlank(_notes.text),
          startDate: _startDate,
          endDate: _endDate,
          schedule: _schedule,
          nagIntervalMinutesOverride: _nagIntervalOverride,
          nagCapOverride: _nagCapOverride,
        );
      }
      invalidateMedicationsState(ref);
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

  static String? _nullIfBlank(String s) {
    final trimmed = s.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FormDropdown extends StatelessWidget {
  const _FormDropdown({required this.value, required this.onChanged});

  final MedicationForm? value;
  final ValueChanged<MedicationForm?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MedicationForm?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Form (optional)',
      ),
      items: [
        const DropdownMenuItem<MedicationForm?>(
          child: Text('Unspecified'),
        ),
        for (final f in MedicationForm.values)
          DropdownMenuItem<MedicationForm?>(
            value: f,
            child: Row(
              children: [
                MedicationIcon(form: f, size: 24),
                const SizedBox(width: 8),
                Text(medicationFormLabel(f)),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// "Prescribed by" dropdown backed by the active Person's care
/// providers.
///
/// Design choices worth knowing:
///
/// * Archived providers are kept in the list so that editing an old
///   medication still shows whoever originally prescribed it —
///   clinical history shouldn't silently drop links. They render in
///   a separate group with an "(archived)" suffix so the user can
///   tell at a glance.
/// * The picker hides itself when [personId] is null (no active
///   Person yet / loading). The free-text "Prescriber note" field
///   below still lets the user capture a name in that case.
/// * Loading / error states collapse the picker into a disabled
///   placeholder rather than a full-screen spinner. The rest of the
///   form is usable while providers resolve.
class _PrescriberPicker extends ConsumerWidget {
  const _PrescriberPicker({
    required this.personId,
    required this.value,
    required this.onChanged,
  });

  final String? personId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = personId;
    if (pid == null) return const SizedBox.shrink();

    final pickerAsync = ref.watch(careProviderPickerProvider(pid));
    return pickerAsync.when(
      loading: () => const _PickerSkeleton(),
      error: (_, _) => const _PickerSkeleton(errored: true),
      data: (data) {
        final active = data.active;
        final archived = data.archived;
        // Dropdown must always include the currently-selected value,
        // even if it somehow isn't in either list (shouldn't happen,
        // but defends against stale state). We surface it as "Unknown
        // provider" so the user can choose to clear it.
        final knownIds = <String>{
          for (final p in active) p.id,
          for (final p in archived) p.id,
        };
        final orphan = value != null && !knownIds.contains(value);

        return DropdownButtonFormField<String?>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Prescribed by (optional)',
            helperText: 'Pick a saved provider to keep links up to date.',
          ),
          items: [
            const DropdownMenuItem<String?>(
              child: Text('— None —'),
            ),
            for (final p in active) _providerMenuItem(p, archived: false),
            if (archived.isNotEmpty)
              const DropdownMenuItem<String?>(
                enabled: false,
                child: Text(
                  'Archived',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            for (final p in archived) _providerMenuItem(p, archived: true),
            if (orphan)
              DropdownMenuItem<String?>(
                value: value,
                child: const Text('Unknown provider'),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  DropdownMenuItem<String?> _providerMenuItem(
    CareProvider provider, {
    required bool archived,
  }) {
    final suffix = <String>[
      labelForKind(provider.kind),
      if (provider.specialty != null && provider.specialty!.trim().isNotEmpty)
        provider.specialty!.trim(),
    ].join(' · ');
    final head =
        archived ? '${provider.name} (archived)' : provider.name;
    final label = suffix.isEmpty ? head : '$head  ·  $suffix';
    return DropdownMenuItem<String?>(
      value: provider.id,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PickerSkeleton extends StatelessWidget {
  const _PickerSkeleton({this.errored = false});

  final bool errored;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Prescribed by (optional)',
        helperText: errored
            ? "Couldn't load providers — try again later."
            : 'Loading providers…',
      ),
      child: const Text('—'),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helpText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final shown = value == null ? label : _formatDate(value!);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime.utc(1900),
                lastDate: DateTime.utc(2100),
                helpText: label,
              );
              if (picked != null) {
                onChanged(DateTime.utc(picked.year, picked.month, picked.day));
              }
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(shown),
                  if (helpText != null)
                    Text(
                      helpText!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear date',
            icon: const Icon(Icons.close),
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

/// Archive / Restore affordance at the bottom of the edit form.
///
/// "Archive" (not "Delete") is deliberate: stopping a medication is
/// information we want to keep, not destroy. Restore is a one-tap undo
/// inside the edit screen for an archived row.
class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.medication});

  final Medication medication;

  bool get _isArchived => medication.deletedAt != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (_isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore medication'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _restore(context, ref),
      );
    }
    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive medication',
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
        title: Text('Archive ${medication.name}?'),
        content: const Text(
          "It'll move to the Archived section on this screen. Nothing "
          'is lost — you can restore it any time, and the history stays '
          'on this device.',
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
    final repo = ref.read(medicationRepositoryProvider);
    try {
      await repo.archive(medication.id);
      invalidateMedicationsState(ref);
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
    final repo = ref.read(medicationRepositoryProvider);
    try {
      await repo.restore(medication.id);
      invalidateMedicationsState(ref);
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
