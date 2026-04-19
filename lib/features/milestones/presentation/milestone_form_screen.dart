import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/milestones/presentation/milestones_list_screen.dart'
    as milestone_labels show labelForKind;
import 'package:were_all_in_this_together/features/milestones/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart'
    as provider_labels show labelForKind;
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Form for creating or editing a [Milestone].
///
/// Passed `null` [initialMilestone] → create mode, scoped to the
/// active Person. Non-null → edit mode with an Archive / Restore
/// action at the bottom, matching the other domain forms.
///
/// Precision is a first-class input here — the user picks "how
/// precisely do I know when this happened" separately from the
/// date picker, because "sometime in 2019" and "March 14, 2019"
/// are different claims and the app should honour whichever the
/// user can actually make.
class MilestoneFormScreen extends ConsumerStatefulWidget {
  const MilestoneFormScreen({this.initialMilestone, super.key});

  final Milestone? initialMilestone;

  bool get isEditing => initialMilestone != null;

  @override
  ConsumerState<MilestoneFormScreen> createState() =>
      _MilestoneFormScreenState();
}

class _MilestoneFormScreenState extends ConsumerState<MilestoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late MilestoneKind _kind;
  late MilestonePrecision _precision;
  late DateTime _occurredAt;
  String? _providerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialMilestone;
    _title = TextEditingController(text: seed?.title ?? '');
    _notes = TextEditingController(text: seed?.notes ?? '');
    _kind = seed?.kind ?? MilestoneKind.life;
    _precision = seed?.precision ?? MilestonePrecision.day;
    // For existing milestones, show the stored canonical UTC instant
    // as-is in the pickers (so a "month" precision milestone opens
    // on the 1st, a "year" one opens on Jan 1). New milestones start
    // at today so the user only has to *reduce* the date instead of
    // navigating years.
    _occurredAt = seed?.occurredAt.toLocal() ?? DateTime.now();
    _providerId = seed?.providerId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialMilestone!.title}'
        : 'Add milestone';

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
                _KindPicker(
                  value: _kind,
                  onChanged: (v) => setState(() => _kind = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    helperText: _helperForKind(_kind),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _PrecisionPicker(
                  value: _precision,
                  onChanged: (v) => setState(() => _precision = v),
                ),
                const SizedBox(height: 16),
                _OccurredAtField(
                  value: _occurredAt,
                  precision: _precision,
                  onChanged: (v) => setState(() => _occurredAt = v),
                ),
                const SizedBox(height: 16),
                _ProviderPicker(
                  personId: _effectivePersonId(),
                  value: _providerId,
                  onChanged: (v) => setState(() => _providerId = v),
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
                        "Anything you'll want to remember — context, "
                        'names, how it went.',
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ArchiveOrRestoreButton(
                    milestone: widget.initialMilestone!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _effectivePersonId() {
    return widget.initialMilestone?.personId ??
        ref.watch(activePersonIdProvider).value;
  }

  static String _helperForKind(MilestoneKind k) {
    switch (k) {
      case MilestoneKind.diagnosis:
        return 'Diagnosed with ASD, ADHD, peanut allergy…';
      case MilestoneKind.vaccine:
        return 'Flu shot, MMR booster, COVID dose 3…';
      case MilestoneKind.development:
        return 'First word, first steps, rode a bike…';
      case MilestoneKind.health:
        return 'ER visit, surgery, broken arm…';
      case MilestoneKind.life:
        return 'Moved house, started school, adopted a dog…';
      case MilestoneKind.other:
        return 'Anything else worth remembering.';
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    final repo = ref.read(milestoneRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.isEditing) {
        await repo.update(
          widget.initialMilestone!.copyWith(
            kind: _kind,
            title: _title.text.trim(),
            occurredAt: _occurredAt.toUtc(),
            precision: _precision,
            providerId: _providerId,
            notes: _nullIfBlank(_notes.text),
          ),
        );
      } else {
        final personId = await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          throw StateError('No active Person when creating a milestone');
        }
        await repo.create(
          personId: personId,
          kind: _kind,
          title: _title.text.trim(),
          occurredAt: _occurredAt.toUtc(),
          precision: _precision,
          providerId: _providerId,
          notes: _nullIfBlank(_notes.text),
        );
      }
      invalidateMilestonesState(ref);
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

class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.value, required this.onChanged});

  final MilestoneKind value;
  final ValueChanged<MilestoneKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MilestoneKind>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
      ),
      items: [
        for (final k in MilestoneKind.values)
          DropdownMenuItem<MilestoneKind>(
            value: k,
            child: Text(milestone_labels.labelForKind(k)),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _PrecisionPicker extends StatelessWidget {
  const _PrecisionPicker({required this.value, required this.onChanged});

  final MilestonePrecision value;
  final ValueChanged<MilestonePrecision> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MilestonePrecision>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'How precisely?',
        helperText:
            "Pick what you actually know — 'sometime in 2019' counts.",
      ),
      items: const [
        DropdownMenuItem(
          value: MilestonePrecision.year,
          child: Text('Just the year'),
        ),
        DropdownMenuItem(
          value: MilestonePrecision.month,
          child: Text('The month'),
        ),
        DropdownMenuItem(
          value: MilestonePrecision.day,
          child: Text('The day'),
        ),
        DropdownMenuItem(
          value: MilestonePrecision.exact,
          child: Text('Day and time'),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Date / time picker row that adapts to [precision].
///
/// We don't hide controls when the precision is coarse: all four
/// tiers use the same date picker. The repository canonicalises
/// the stored instant, so the user can flip precision back and
/// forth without feeling like they're losing data entered at a
/// finer grain.
class _OccurredAtField extends StatelessWidget {
  const _OccurredAtField({
    required this.value,
    required this.precision,
    required this.onChanged,
  });

  final DateTime value;
  final MilestonePrecision precision;
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
              _preview(value, precision),
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
      // Milestones can reach far back ("born in 1985") and are
      // sometimes near-future commitments ("scheduled to start
      // school next month"). Wider window than appointments.
      firstDate: DateTime(DateTime.now().year - 100),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate == null) return;

    if (precision != MilestonePrecision.exact) {
      onChanged(
        DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
      );
      return;
    }

    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (pickedTime == null) {
      onChanged(
        DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          value.hour,
          value.minute,
        ),
      );
      return;
    }
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

  /// Renders the in-form preview — shares the same rules as
  /// `formatMilestoneDate` so what users see while editing matches
  /// the list afterwards.
  static String _preview(DateTime local, MilestonePrecision precision) {
    switch (precision) {
      case MilestonePrecision.year:
        return '${local.year}';
      case MilestonePrecision.month:
        return '${_monthName(local.month)} ${local.year}';
      case MilestonePrecision.day:
        return '${_monthShort(local.month)} ${local.day}, ${local.year}';
      case MilestonePrecision.exact:
        final hh = local.hour.toString().padLeft(2, '0');
        final mm = local.minute.toString().padLeft(2, '0');
        return '${_monthShort(local.month)} ${local.day}, ${local.year}'
            ' at $hh:$mm';
    }
  }

  static String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][m - 1];

  static String _monthShort(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}

/// Optional link to a CareProvider. Mirrors the appointment form's
/// picker: archived providers remain selectable so historical
/// attribution survives retirement.
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
      provider_labels.labelForKind(provider.kind),
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

class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isArchived = milestone.deletedAt != null;

    if (isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: Text('Restore ${milestone.title}'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _restore(context, ref),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive ${milestone.title}',
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
        title: Text('Archive ${milestone.title}?'),
        content: const Text(
          'Archived milestones drop off the main list. You can restore '
          'them anytime.',
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

    final repo = ref.read(milestoneRepositoryProvider);
    try {
      await repo.archive(milestone.id);
      invalidateMilestonesState(ref);
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
    final repo = ref.read(milestoneRepositoryProvider);
    try {
      await repo.restore(milestone.id);
      invalidateMilestonesState(ref);
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
