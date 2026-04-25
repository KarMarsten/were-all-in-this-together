import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart'
    show labelForKind;
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Form for creating or editing a [CareProvider].
///
/// Passed `null` [initialProvider] → create mode, scoped to the active
/// Person. Non-null → edit mode with an "Archive" / "Restore" action
/// depending on the row's current state.
///
/// Field choices follow the architecture-doc data model — name + kind
/// required, free-text specialty / phone / address / portal URL /
/// notes optional. All sensitive fields encrypt to the owning Person's
/// key via the repository.
class CareProviderFormScreen extends ConsumerStatefulWidget {
  const CareProviderFormScreen({this.initialProvider, super.key});

  final CareProvider? initialProvider;

  bool get isEditing => initialProvider != null;

  @override
  ConsumerState<CareProviderFormScreen> createState() =>
      _CareProviderFormScreenState();
}

class _CareProviderFormScreenState
    extends ConsumerState<CareProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _specialty;
  late final TextEditingController _role;
  late final TextEditingController _contactName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _fax;
  late final TextEditingController _address;
  late final TextEditingController _portalLabel;
  late final TextEditingController _portalUrl;
  late final TextEditingController _afterHoursPhone;
  late final TextEditingController _afterHoursInstructions;
  late final TextEditingController _notes;
  late CareProviderKind _kind;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialProvider;
    _name = TextEditingController(text: seed?.name ?? '');
    _specialty = TextEditingController(text: seed?.specialty ?? '');
    _role = TextEditingController(text: seed?.role ?? '');
    _contactName = TextEditingController(text: seed?.contactName ?? '');
    _phone = TextEditingController(text: seed?.phone ?? '');
    _email = TextEditingController(text: seed?.email ?? '');
    _fax = TextEditingController(text: seed?.fax ?? '');
    _address = TextEditingController(text: seed?.address ?? '');
    _portalLabel = TextEditingController(text: seed?.portalLabel ?? '');
    _portalUrl = TextEditingController(text: seed?.portalUrl ?? '');
    _afterHoursPhone = TextEditingController(
      text: seed?.afterHoursPhone ?? '',
    );
    _afterHoursInstructions = TextEditingController(
      text: seed?.afterHoursInstructions ?? '',
    );
    _notes = TextEditingController(text: seed?.notes ?? '');
    // Default new providers to `specialist` — the most common bucket
    // for the kind of providers families track after their PCP is
    // already in place. Users can drop into PCP / therapist / etc.
    // from the dropdown; defaulting to a specific value avoids an
    // extra required tap on the common path.
    _kind = seed?.kind ?? CareProviderKind.specialist;
  }

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _role.dispose();
    _contactName.dispose();
    _phone.dispose();
    _email.dispose();
    _fax.dispose();
    _address.dispose();
    _portalLabel.dispose();
    _portalUrl.dispose();
    _afterHoursPhone.dispose();
    _afterHoursInstructions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit ${widget.initialProvider!.name}'
        : 'Add provider';

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
                        'Dr. Chen, Park Pediatrics, Ms. Alvarez (OT)…',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CareProviderKind>(
                  initialValue: _kind,
                  decoration: const InputDecoration(
                    labelText: 'Kind',
                  ),
                  items: [
                    for (final k in CareProviderKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Text(labelForKind(k)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _kind = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specialty,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Specialty (optional)',
                    hintText: 'OT, developmental pediatrics, GI, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _role,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Role / relationship (optional)',
                    hintText: 'Medication prescriber, IEP contact, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Contact person (optional)',
                    hintText: 'Scheduler, nurse line, front desk, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '+1 555-123-4567',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'office@example.com',
                  ),
                  validator: _emailError,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fax,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Fax (optional)',
                    hintText: '+1 555-222-3333',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portalLabel,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Portal label (optional)',
                    hintText: 'MyChart, intake portal, billing portal',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portalUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Portal URL (optional)',
                    hintText: 'https://mychart.example.com',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    final parsed = Uri.tryParse(trimmed);
                    if (parsed == null ||
                        !(parsed.isScheme('http') ||
                            parsed.isScheme('https'))) {
                      return 'Must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _afterHoursPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'After-hours phone (optional)',
                    hintText: '+1 555-999-0000',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _afterHoursInstructions,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'After-hours instructions (optional)',
                    helperText: 'What to do when the office is closed.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    helperText:
                        'Receptionist, office hours, in-network dates, '
                        'anything worth remembering.',
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ArchiveOrRestoreButton(provider: widget.initialProvider!),
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
    final repo = ref.read(careProviderRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.isEditing) {
        await repo.update(
          widget.initialProvider!.copyWith(
            name: _name.text.trim(),
            kind: _kind,
            specialty: _nullIfBlank(_specialty.text),
            role: _nullIfBlank(_role.text),
            contactName: _nullIfBlank(_contactName.text),
            phone: _nullIfBlank(_phone.text),
            email: _nullIfBlank(_email.text),
            fax: _nullIfBlank(_fax.text),
            address: _nullIfBlank(_address.text),
            portalLabel: _nullIfBlank(_portalLabel.text),
            portalUrl: _nullIfBlank(_portalUrl.text),
            afterHoursPhone: _nullIfBlank(_afterHoursPhone.text),
            afterHoursInstructions: _nullIfBlank(
              _afterHoursInstructions.text,
            ),
            notes: _nullIfBlank(_notes.text),
          ),
        );
      } else {
        // Create mode runs under the currently-active Person — the form
        // is only reachable from the list screen, which already funnels
        // through the "Add someone first" empty state when the roster
        // is empty.
        final personId = await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          throw StateError('No active Person when creating a care provider');
        }
        await repo.create(
          personId: personId,
          name: _name.text.trim(),
          kind: _kind,
          specialty: _nullIfBlank(_specialty.text),
          role: _nullIfBlank(_role.text),
          contactName: _nullIfBlank(_contactName.text),
          phone: _nullIfBlank(_phone.text),
          email: _nullIfBlank(_email.text),
          fax: _nullIfBlank(_fax.text),
          address: _nullIfBlank(_address.text),
          portalLabel: _nullIfBlank(_portalLabel.text),
          portalUrl: _nullIfBlank(_portalUrl.text),
          afterHoursPhone: _nullIfBlank(_afterHoursPhone.text),
          afterHoursInstructions: _nullIfBlank(
            _afterHoursInstructions.text,
          ),
          notes: _nullIfBlank(_notes.text),
        );
      }
      invalidateCareProvidersState(ref);
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

  static String? _emailError(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse('mailto:$trimmed');
    if (parsed == null ||
        parsed.path.isEmpty ||
        !trimmed.contains('@') ||
        trimmed.contains(' ')) {
      return 'Enter an email address or leave it blank';
    }
    return null;
  }
}

/// Bottom-of-form action that toggles a provider between active and
/// archived, with a confirmation dialog on the archive path. The
/// restore path is one-tap because it's reversible and low-risk.
class _ArchiveOrRestoreButton extends ConsumerWidget {
  const _ArchiveOrRestoreButton({required this.provider});

  final CareProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isArchived = provider.deletedAt != null;

    if (isArchived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: Text('Restore ${provider.name}'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _restore(context, ref),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text(
        'Archive ${provider.name}',
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
        title: Text('Archive ${provider.name}?'),
        content: const Text(
          'This provider will drop off the main list but stay linked to '
          'any medications that reference them. You can restore them '
          'anytime.',
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

    final repo = ref.read(careProviderRepositoryProvider);
    try {
      await repo.archive(provider.id);
      invalidateCareProvidersState(ref);
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
    final repo = ref.read(careProviderRepositoryProvider);
    try {
      await repo.restore(provider.id);
      invalidateCareProvidersState(ref);
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
