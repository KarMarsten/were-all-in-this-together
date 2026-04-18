import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// Form for creating or editing a [Person].
///
/// Passed `null` [initialPerson] → create mode. Non-null → edit mode, with
/// a "Remove" action at the bottom that soft-deletes after confirmation.
///
/// Field choices are deliberately minimal: a display name, pronouns, DOB,
/// and a free-form framing-preferences note. None of them are clinical
/// labels, diagnoses, or care roles — those belong on later, domain-
/// specific screens (Providers, Medications, etc.) so the Person itself
/// stays close to "who is this human" and doesn't become a role record.
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({this.initialPerson, super.key});

  final Person? initialPerson;

  bool get isEditing => initialPerson != null;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _pronouns;
  late final TextEditingController _framingNotes;
  DateTime? _dob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPerson;
    _displayName = TextEditingController(text: seed?.displayName ?? '');
    _pronouns = TextEditingController(text: seed?.pronouns ?? '');
    _framingNotes =
        TextEditingController(text: seed?.preferredFramingNotes ?? '');
    _dob = seed?.dob;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _pronouns.dispose();
    _framingNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialPerson!.displayName}'
        : 'Add someone';

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
                  controller: _displayName,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    helperText:
                        'What to call them in the app. Chosen name is fine.',
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
                  controller: _pronouns,
                  decoration: const InputDecoration(
                    labelText: 'Pronouns (optional)',
                    hintText: 'e.g. she/her, they/them, he/him',
                  ),
                ),
                const SizedBox(height: 16),
                _DobField(
                  value: _dob,
                  onChanged: (d) => setState(() => _dob = d),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _framingNotes,
                  decoration: const InputDecoration(
                    labelText: 'Framing preferences (optional)',
                    helperText:
                        'How they prefer to be described — identity-first '
                        'vs person-first, community vocabulary, etc.',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _RemoveButton(person: widget.initialPerson!),
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
    final repo = ref.read(personRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.isEditing) {
        await repo.update(
          widget.initialPerson!.copyWith(
            displayName: _displayName.text.trim(),
            pronouns: _nullIfBlank(_pronouns.text),
            dob: _dob,
            preferredFramingNotes: _nullIfBlank(_framingNotes.text),
          ),
        );
      } else {
        await repo.create(
          displayName: _displayName.text.trim(),
          pronouns: _nullIfBlank(_pronouns.text),
          dob: _dob,
          preferredFramingNotes: _nullIfBlank(_framingNotes.text),
        );
      }
      ref.invalidate(peopleListProvider);
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

class _DobField extends StatelessWidget {
  const _DobField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label =
        value == null ? 'Date of birth (optional)' : _formatDate(value!);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime.utc(1900),
                lastDate: DateTime.now(),
                helpText: 'Date of birth',
              );
              if (picked != null) {
                onChanged(DateTime.utc(picked.year, picked.month, picked.day));
              }
            },
            icon: const Icon(Icons.cake_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(label),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

class _RemoveButton extends ConsumerWidget {
  const _RemoveButton({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      icon: Icon(Icons.person_remove_outlined, color: scheme.error),
      label: Text(
        'Remove ${person.displayName}',
        style: TextStyle(color: scheme.error),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _confirmAndRemove(context, ref),
    );
  }

  Future<void> _confirmAndRemove(BuildContext context, WidgetRef ref) async {
    // Capture the messenger up front so we can still surface failures
    // after the async gap without reaching back into `context`.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      // Don't let a stray tap dismiss a deletion confirm.
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${person.displayName}?'),
        content: const Text(
          'Their information will be hidden from the app but kept on this '
          'device so it can sync later if you ever change your mind.\n\n'
          "You can't fully erase yet.",
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final repo = ref.read(personRepositoryProvider);
    try {
      await repo.softDelete(person.id);
      ref.invalidate(peopleListProvider);
      if (!context.mounted) return;
      context.pop();
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't remove: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
