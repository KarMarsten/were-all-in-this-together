import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_sync.dart';
import 'package:were_all_in_this_together/features/appointments/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart'
    show labelForKind;
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Form for creating or editing an [Appointment].
///
/// Passed `null` [initialAppointment] → create mode, scoped to the
/// active Person. Non-null → edit mode with an Archive / Restore
/// action at the bottom, matching the other domain forms.
///
/// Reminder lead is persisted now even though notifications
/// haven't been wired yet — the value is cheap to store, gives
/// users a familiar "ask me 60 min before" field on day one, and
/// the upcoming-reminders PR won't need a schema change to light
/// it up.
class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({this.initialAppointment, super.key});

  final Appointment? initialAppointment;

  bool get isEditing => initialAppointment != null;

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState
    extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late final TextEditingController _duration;
  late DateTime _scheduledAt;
  String? _providerId;
  int? _reminderLeadMinutes;
  bool _saving = false;

  /// Reminder lead options in minutes. Covers the common "on my
  /// way / give me time to gather papers / day before to reschedule
  /// if needed" cases without drowning the user in choices. `null`
  /// means no reminder.
  static const _reminderOptions = <int?>[null, 15, 30, 60, 120, 1440];

  @override
  void initState() {
    super.initState();
    final seed = widget.initialAppointment;
    _title = TextEditingController(text: seed?.title ?? '');
    _location = TextEditingController(text: seed?.location ?? '');
    _notes = TextEditingController(text: seed?.notes ?? '');
    _duration = TextEditingController(
      text: seed?.durationMinutes?.toString() ?? '',
    );
    // Default a fresh appointment to the next top-of-hour in the
    // user's local timezone. Users almost always round up, and
    // picking "now" would produce a reminder that may already have
    // passed by the time they finish typing.
    _scheduledAt = seed?.scheduledAt.toLocal() ?? _defaultFutureSlot();
    _providerId = seed?.providerId;
    _reminderLeadMinutes = seed?.reminderLeadMinutes ?? 60;
  }

  static DateTime _defaultFutureSlot() {
    final now = DateTime.now();
    final nextHour = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 1,
    );
    return nextHour;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialAppointment!.title}'
        : 'Add appointment';

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
                  controller: _title,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    helperText:
                        'Dr. Chen — flu shot, IEP review, OT session…',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _ScheduledAtField(
                  value: _scheduledAt,
                  onChanged: (v) => setState(() => _scheduledAt = v),
                ),
                const SizedBox(height: 16),
                _ProviderPicker(
                  personId: _effectivePersonId(),
                  value: _providerId,
                  onChanged: (v) => setState(() => _providerId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    hintText:
                        "Dr. Chen's office, Zoom, school library…",
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration in minutes (optional)',
                    hintText: '30, 45, 60…',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    final n = int.tryParse(trimmed);
                    if (n == null || n <= 0) {
                      return 'Enter a whole number of minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _reminderLeadMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Reminder',
                  ),
                  items: [
                    for (final v in _reminderOptions)
                      DropdownMenuItem<int?>(
                        value: v,
                        child: Text(_reminderLabel(v)),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _reminderLeadMinutes = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    helperText:
                        'Questions to ask, forms to bring, insurance '
                        "info — anything you'll want in your pocket.",
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ArchiveOrRestoreButton(
                    appointment: widget.initialAppointment!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// In edit mode the appointment's owning Person is what matters
  /// for the provider picker (deep links to edit may be opened
  /// under a different active Person). In create mode we fall
  /// back to the currently-active Person.
  String? _effectivePersonId() {
    return widget.initialAppointment?.personId ??
        ref.watch(activePersonIdProvider).value;
  }

  static String _reminderLabel(int? minutes) {
    if (minutes == null) return 'No reminder';
    if (minutes < 60) return '$minutes minutes before';
    if (minutes == 60) return '1 hour before';
    if (minutes == 1440) return '1 day before';
    if (minutes % 60 == 0) return '${minutes ~/ 60} hours before';
    return '$minutes minutes before';
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    final repo = ref.read(appointmentRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final durationText = _duration.text.trim();
      final durationMinutes =
          durationText.isEmpty ? null : int.parse(durationText);
      if (widget.isEditing) {
        await repo.update(
          widget.initialAppointment!.copyWith(
            title: _title.text.trim(),
            scheduledAt: _scheduledAt.toUtc(),
            providerId: _providerId,
            location: _nullIfBlank(_location.text),
            durationMinutes: durationMinutes,
            notes: _nullIfBlank(_notes.text),
            reminderLeadMinutes: _reminderLeadMinutes,
          ),
        );
      } else {
        final personId = await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          throw StateError('No active Person when creating an appointment');
        }
        await repo.create(
          personId: personId,
          title: _title.text.trim(),
          scheduledAt: _scheduledAt.toUtc(),
          providerId: _providerId,
          location: _nullIfBlank(_location.text),
          durationMinutes: durationMinutes,
          notes: _nullIfBlank(_notes.text),
          reminderLeadMinutes: _reminderLeadMinutes,
        );
      }
      invalidateAppointmentsState(ref);
      unawaited(reconcileAppointmentRemindersOnce(ref));
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

/// Combined date + time picker row. Splits the interaction so each
/// picker stays simple: "date first, then time" matches how most
/// people enter appointments.
class _ScheduledAtField extends StatelessWidget {
  const _ScheduledAtField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'When',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _format(value),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Change'),
            onPressed: () => _pick(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: value,
      // Wide range on both sides: appointments can be scheduled
      // years out (school-age milestones) and historical entry is
      // legit ("note that Dr. Chen saw us last month, I forgot to
      // log it").
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (pickedTime == null) return;
    onChanged(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  static String _format(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $hh:$mm';
  }
}

/// Mirror of the medication form's `_PrescriberPicker`, scoped to
/// appointments. Archived providers stay selectable so historical
/// links survive retirement.
class _ProviderPicker extends ConsumerWidget {
  const _ProviderPicker({
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
        // Dropdown must always include the currently-selected
        // value, even if it somehow isn't in either list. We
        // surface it as "Unknown provider" so the user can choose
        // to clear it.
        final knownIds = <String>{
          for (final p in active) p.id,
          for (final p in archived) p.id,
        };
        final orphan = value != null && !knownIds.contains(value);

        return DropdownButtonFormField<String?>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Provider (optional)',
            helperText:
                'Link to someone on the care team to keep attributions '
                'consistent.',
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
    final head = archived ? '${provider.name} (archived)' : provider.name;
    final label = suffix.isEmpty ? head : '$head  ·  $suffix';
    return DropdownMenuItem<String?>(
      value: provider.id,
      child: Text(label, overflow: TextOverflow.ellipsis),
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
        labelText: 'Provider (optional)',
        helperText: errored
            ? "Couldn't load providers — try again later."
            : 'Loading providers…',
      ),
      child: const Text('—'),
    );
  }
}

/// Bottom-of-form action that toggles an appointment between
/// active and archived.
class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isArchived = appointment.deletedAt != null;

    if (isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: Text('Restore ${appointment.title}'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _restore(context, ref),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive ${appointment.title}',
        style: TextStyle(color: scheme.error),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _confirmAndArchive(context, ref),
    );
  }

  Future<void> _confirmAndArchive(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive ${appointment.title}?'),
        content: const Text(
          'Archived appointments drop off the main list. You can '
          'restore them anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(appointmentRepositoryProvider);
    try {
      await repo.archive(appointment.id);
      invalidateAppointmentsState(ref);
      unawaited(reconcileAppointmentRemindersOnce(ref));
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
    final repo = ref.read(appointmentRepositoryProvider);
    try {
      await repo.restore(appointment.id);
      invalidateAppointmentsState(ref);
      unawaited(reconcileAppointmentRemindersOnce(ref));
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
