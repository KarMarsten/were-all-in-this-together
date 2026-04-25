import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/programs/data/program_repository.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({this.initialProgram, super.key});

  final Program? initialProgram;

  bool get isEditing => initialProgram != null;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _contactName;
  late final TextEditingController _contactRole;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _websiteUrl;
  late final TextEditingController _hours;
  late final TextEditingController _notes;
  late ProgramKind _kind;
  String? _providerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialProgram;
    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _contactName = TextEditingController(text: s?.contactName ?? '');
    _contactRole = TextEditingController(text: s?.contactRole ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _websiteUrl = TextEditingController(text: s?.websiteUrl ?? '');
    _hours = TextEditingController(text: s?.hours ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
    _kind = s?.kind ?? ProgramKind.school;
    _providerId = s?.providerId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _contactName.dispose();
    _contactRole.dispose();
    _email.dispose();
    _address.dispose();
    _websiteUrl.dispose();
    _hours.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(programRepositoryProvider);
      if (widget.isEditing) {
        final cur = widget.initialProgram!;
        await repo.update(
          cur.copyWith(
            kind: _kind,
            name: _name.text.trim(),
            phone: _nullIfBlank(_phone.text),
            contactName: _nullIfBlank(_contactName.text),
            contactRole: _nullIfBlank(_contactRole.text),
            email: _nullIfBlank(_email.text),
            address: _nullIfBlank(_address.text),
            websiteUrl: _nullIfBlank(_websiteUrl.text),
            hours: _nullIfBlank(_hours.text),
            notes: _nullIfBlank(_notes.text),
            providerId: _providerId,
          ),
        );
      } else {
        final personId = await ref.read(activePersonIdProvider.future);
        if (personId == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('No active person selected.')),
          );
          return;
        }
        await repo.create(
          personId: personId,
          kind: _kind,
          name: _name.text.trim(),
          phone: _nullIfBlank(_phone.text),
          contactName: _nullIfBlank(_contactName.text),
          contactRole: _nullIfBlank(_contactRole.text),
          email: _nullIfBlank(_email.text),
          address: _nullIfBlank(_address.text),
          websiteUrl: _nullIfBlank(_websiteUrl.text),
          hours: _nullIfBlank(_hours.text),
          notes: _nullIfBlank(_notes.text),
          providerId: _providerId,
        );
      }
      invalidateProgramsState(ref);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
      context.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't save: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _nullIfBlank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static String? _emailError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  static String? _urlError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final normalized = ProgramRepository.normalizeUserUrl(value);
    final parsed = Uri.tryParse(normalized);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return 'Enter a valid website URL';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit program' : 'Add program';
    final personIdAsync = widget.isEditing
        ? AsyncValue.data(widget.initialProgram!.personId)
        : ref.watch(activePersonIdProvider);
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
                DropdownButtonFormField<ProgramKind>(
                  key: ValueKey(_kind),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kind',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final k in ProgramKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Text(labelForProgramKind(k)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _kind = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Roosevelt Elementary, summer camp…',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please add a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Main phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Contact name (optional)',
                    hintText: 'Front desk, Ms. Patel, camp director…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactRole,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Contact role (optional)',
                    hintText: 'Teacher, registrar, coordinator…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: _emailError,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Website / portal URL (optional)',
                    hintText: 'school.example.org',
                    border: OutlineInputBorder(),
                  ),
                  validator: _urlError,
                ),
                const SizedBox(height: 16),
                personIdAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text("Couldn't load providers: $e"),
                  data: (personId) {
                    if (personId == null) return const SizedBox.shrink();
                    final providersAsync = ref.watch(
                      careProviderPickerProvider(personId),
                    );
                    return providersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text("Couldn't load providers: $e"),
                      data: (providers) => _ProviderLinkField(
                        value: _providerId,
                        providers: providers.all,
                        onChanged: (value) {
                          setState(() => _providerId = value);
                        },
                      ),
                    );
                  },
                ),
                if (personIdAsync.hasValue && personIdAsync.value != null)
                  const SizedBox(height: 16),
                TextFormField(
                  controller: _hours,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Schedule / hours (optional)',
                    hintText: 'Mon–Fri 8:00–3:00, summer session dates…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Office hours, who to ask for, car line…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  _ArchiveOrRestore(program: widget.initialProgram!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveOrRestore extends ConsumerWidget {
  const _ArchiveOrRestore({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = program.deletedAt != null;
    final scheme = Theme.of(context).colorScheme;
    if (archived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore program'),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(programRepositoryProvider).restore(program.id);
            invalidateProgramsState(ref);
            messenger.showSnackBar(const SnackBar(content: Text('Restored')));
            if (context.mounted) context.pop();
          } on Object catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text("Couldn't restore: $e")),
            );
          }
        },
      );
    }
    return OutlinedButton.icon(
      icon: Icon(Icons.archive_outlined, color: scheme.error),
      label: Text('Archive program', style: TextStyle(color: scheme.error)),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Archive this program?'),
            content: const Text(
              'Archived programs disappear from the main list. You can '
              'restore them from this screen.',
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
          await ref.read(programRepositoryProvider).archive(program.id);
          invalidateProgramsState(ref);
          messenger.showSnackBar(const SnackBar(content: Text('Archived')));
          if (context.mounted) context.pop();
        } on Object catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text("Couldn't archive: $e")),
          );
        }
      },
    );
  }
}

class _ProviderLinkField extends StatelessWidget {
  const _ProviderLinkField({
    required this.value,
    required this.providers,
    required this.onChanged,
  });

  final String? value;
  final List<CareProvider> providers;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasCurrent =
        value != null && !providers.any((provider) => provider.id == value);
    return DropdownButtonFormField<String>(
      initialValue: value ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Linked provider (optional)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('None')),
        if (hasCurrent)
          DropdownMenuItem(
            value: value,
            child: const Text('Saved provider (not available)'),
          ),
        for (final provider in providers)
          DropdownMenuItem(
            value: provider.id,
            child: Text(_providerLabel(provider)),
          ),
      ],
      onChanged: (next) {
        if (next == null) return;
        onChanged(next.isEmpty ? null : next);
      },
    );
  }

  static String _providerLabel(CareProvider provider) {
    final specialty = provider.specialty?.trim();
    if (specialty == null || specialty.isEmpty) return provider.name;
    return '${provider.name} · $specialty';
  }
}
