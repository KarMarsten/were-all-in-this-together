import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/presentation/providers.dart';

/// Form for appending a freeform **note** event to a medication's
/// history timeline.
///
/// The reason this exists even though `MedicationRepository`
/// already auto-logs every create / update / archive / restore:
/// most users want to record regimen changes that happened *before*
/// the app was installed. "Started Concerta 10mg in 2019 per Dr.
/// Chen" is real history, but typing it into the current
/// medication row would be wrong — the current row describes the
/// regimen *now*.
///
/// First pass is intentionally simple: an occurred-at date picker
/// and a free-text body. We deliberately do not expose structured
/// field diffs (dose: 10mg → 20mg) for manual entry — a narrative
/// note reads cleanly on the timeline and matches how humans
/// actually remember their med history.
class MedicationEventFormScreen extends ConsumerStatefulWidget {
  const MedicationEventFormScreen({
    required this.medicationId,
    required this.personId,
    super.key,
  });

  /// Medication this note will be attached to. Non-null because the
  /// route that drives us always has a resolved medication id in
  /// hand; the screen has no meaning otherwise.
  final String medicationId;

  /// Owning Person's id, needed so the encrypted payload can be
  /// sealed under the right key. The history screen's caller already
  /// knows this (it was resolved when we loaded the medication);
  /// passing it here avoids a second DB round-trip in the form.
  final String personId;

  @override
  ConsumerState<MedicationEventFormScreen> createState() =>
      _MedicationEventFormScreenState();
}

class _MedicationEventFormScreenState
    extends ConsumerState<MedicationEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  DateTime _occurredAt = _dateOnly(DateTime.now());
  bool _saving = false;

  /// Strip the time component so the date picker and the stored
  /// event agree on "this happened on day X". Time-of-day would
  /// imply more precision than a backfilled memory actually has.
  static DateTime _dateOnly(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add history note'),
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
                _DateField(
                  value: _occurredAt,
                  onChanged: (picked) =>
                      setState(() => _occurredAt = picked),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  minLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    alignLabelWithHint: true,
                    helperText: 'e.g. "Started 10mg once daily, '
                        'prescribed by Dr. Chen."',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a short description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(medicationEventRepositoryProvider);
      await repo.create(
        medicationId: widget.medicationId,
        personId: widget.personId,
        kind: MedicationEventKind.note,
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
      );
      // Invalidate the timeline provider so the history screen
      // picks up the new row without a pull-to-refresh.
      ref.invalidate(medicationHistoryProvider(widget.medicationId));
      if (!mounted) return;
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: $e")),
      );
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'When did this happen?',
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
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                // A twenty-year backlog is enough for every
                // practical backfill ("when was your kid first
                // prescribed X?") without letting the user fat-
                // finger 1902.
                firstDate:
                    DateTime.utc(DateTime.now().year - 20),
                // Future dates are legit — a caregiver may be
                // recording "as of next Monday, new dose".
                lastDate:
                    DateTime.utc(DateTime.now().year + 2),
              );
              if (picked != null) {
                onChanged(
                  DateTime.utc(picked.year, picked.month, picked.day),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _format(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
