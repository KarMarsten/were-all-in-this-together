import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/apps_sites/data/app_site_repository.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

class AppSiteFormScreen extends ConsumerStatefulWidget {
  const AppSiteFormScreen({this.initialSite, super.key});

  final AppSite? initialSite;

  bool get isEditing => initialSite != null;

  @override
  ConsumerState<AppSiteFormScreen> createState() => _AppSiteFormScreenState();
}

class _AppSiteFormScreenState extends ConsumerState<AppSiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _url;
  late final TextEditingController _usernameHint;
  late final TextEditingController _loginNote;
  late final TextEditingController _notes;
  late AppSiteCategory _category;
  String? _providerId;
  String? _programId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSite;
    _title = TextEditingController(text: s?.title ?? '');
    _url = TextEditingController(text: s?.url ?? '');
    _usernameHint = TextEditingController(text: s?.usernameHint ?? '');
    _loginNote = TextEditingController(text: s?.loginNote ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
    _category = s?.category ?? AppSiteCategory.portal;
    _providerId = s?.providerId;
    _programId = s?.programId;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _usernameHint.dispose();
    _loginNote.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(appSiteRepositoryProvider);
      if (widget.isEditing) {
        final cur = widget.initialSite!;
        await repo.update(
          cur.copyWith(
            title: _title.text.trim(),
            url: _url.text.trim(),
            category: _category,
            usernameHint: _nullIfBlank(_usernameHint.text),
            loginNote: _nullIfBlank(_loginNote.text),
            notes: _nullIfBlank(_notes.text),
            providerId: _providerId,
            programId: _programId,
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
          title: _title.text.trim(),
          url: _url.text.trim(),
          category: _category,
          usernameHint: _nullIfBlank(_usernameHint.text),
          loginNote: _nullIfBlank(_loginNote.text),
          notes: _nullIfBlank(_notes.text),
          providerId: _providerId,
          programId: _programId,
        );
      }
      invalidateAppSitesState(ref);
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

  static String? _urlError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Please add a URL';
    final normalized = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid URL';
    }
    return null;
  }

  static Program? _programById(List<Program> programs, String? id) {
    if (id == null) return null;
    for (final program in programs) {
      if (program.id == id) return program;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final opener = ref.watch(urlOpenerProvider);
    final title = widget.isEditing ? 'Edit link' : 'Add link';
    final personIdAsync = widget.isEditing
        ? AsyncValue.data(widget.initialSite!.personId)
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
                DropdownButtonFormField<AppSiteCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in AppSiteCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(labelForAppSiteCategory(category)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'District parent portal, telehealth login…',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please add a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://… or example.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: _urlError,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final raw = _url.text.trim();
                    if (raw.isEmpty) return;
                    final normalized = AppSiteRepository.normalizeUserUrl(raw);
                    final ok = await opener.openWeb(normalized);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Couldn't open URL — check the link."),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Try URL'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameHint,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username hint (optional)',
                    hintText: 'Email used, student ID hint — not a password.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _loginNote,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Login note (optional)',
                    hintText: '2FA goes to Dad, use school email — no secrets.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Do not store passwords, recovery codes, or security '
                  'answers here. Use a password manager for secrets.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                personIdAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text("Couldn't load linked records: $e"),
                  data: (personId) {
                    if (personId == null) return const SizedBox.shrink();
                    final providersAsync = ref.watch(
                      careProviderPickerProvider(personId),
                    );
                    final programsAsync = ref.watch(
                      allProgramsForPersonProvider(personId),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        providersAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text("Couldn't load providers: $e"),
                          data: (providers) {
                            final linkedProvider =
                                providers.byId(_providerId ?? '');
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProviderLinkField(
                                  value: _providerId,
                                  providers: providers.all,
                                  onChanged: (value) {
                                    setState(() => _providerId = value);
                                  },
                                ),
                                if (linkedProvider != null) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: Text(
                                      'Open ${linkedProvider.name}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () => context.push(
                                      Routes.careProviderDetail(
                                        linkedProvider.id,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        programsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text("Couldn't load programs: $e"),
                          data: (programs) {
                            final linkedProgram = _programById(
                              programs,
                              _programId,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProgramLinkField(
                                  value: _programId,
                                  programs: programs,
                                  onChanged: (value) {
                                    setState(() => _programId = value);
                                  },
                                ),
                                if (linkedProgram != null) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: Text(
                                      'Open ${linkedProgram.name}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () => context.push(
                                      Routes.programEdit(linkedProgram.id),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Which account is yours, bookmark tips — never '
                        'passwords.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  _AppSiteArchiveOrRestore(site: widget.initialSite!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSiteArchiveOrRestore extends ConsumerWidget {
  const _AppSiteArchiveOrRestore({required this.site});

  final AppSite site;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = site.deletedAt != null;
    final scheme = Theme.of(context).colorScheme;
    if (archived) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Restore link'),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(appSiteRepositoryProvider).restore(site.id);
            invalidateAppSitesState(ref);
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
      label: Text('Archive link', style: TextStyle(color: scheme.error)),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Archive this link?'),
            content: const Text(
              'Archived links disappear from the main list. You can restore '
              'them from this screen.',
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
          await ref.read(appSiteRepositoryProvider).archive(site.id);
          invalidateAppSitesState(ref);
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

class _ProgramLinkField extends StatelessWidget {
  const _ProgramLinkField({
    required this.value,
    required this.programs,
    required this.onChanged,
  });

  final String? value;
  final List<Program> programs;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final deduped = <String, Program>{
      for (final program in programs) program.id: program,
    }.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final hasCurrent =
        value != null && !deduped.any((program) => program.id == value);
    return DropdownButtonFormField<String>(
      initialValue: value ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Linked program (optional)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('None')),
        if (hasCurrent)
          DropdownMenuItem(
            value: value,
            child: const Text('Saved program (not available)'),
          ),
        for (final program in deduped)
          DropdownMenuItem(
            value: program.id,
            child: Text(
              '${program.name} · ${labelForProgramKind(program.kind)}',
            ),
          ),
      ],
      onChanged: (next) {
        if (next == null) return;
        onChanged(next.isEmpty ? null : next);
      },
    );
  }
}
