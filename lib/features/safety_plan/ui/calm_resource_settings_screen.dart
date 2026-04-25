import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/safety_plan/data/calm_resource_preferences.dart';

class CalmResourceSettingsScreen extends ConsumerStatefulWidget {
  const CalmResourceSettingsScreen({this.firstRun = false, super.key});

  final bool firstRun;

  @override
  ConsumerState<CalmResourceSettingsScreen> createState() =>
      _CalmResourceSettingsScreenState();
}

class _CalmResourceSettingsScreenState
    extends ConsumerState<CalmResourceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _items = <_EditableCalmResource>[];
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _initialize(CalmResourcePreferences preferences) {
    if (_initialized) return;
    _items
      ..clear()
      ..addAll([
        for (final resource in preferences.resources)
          _EditableCalmResource.fromResource(resource),
      ]);
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final resources = [
      for (final item in _items)
        CalmResource(
          id: item.id,
          kind: item.kind,
          label: item.label.text.trim(),
          url: _normalizeUrl(item.url.text),
        ),
    ];
    try {
      final repo = ref.read(calmResourcePreferencesRepositoryProvider);
      await repo.save(
        CalmResourcePreferences(
          resources: resources,
          setupComplete: true,
        ),
      );
      ref.invalidate(calmResourcePreferencesProvider);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
      if (widget.firstRun) {
        context.go(Routes.home);
      } else {
        context.pop();
      }
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't save Calm resources: $error")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add(CalmResourceKind kind) {
    setState(() {
      _items.add(_EditableCalmResource.blank(kind));
    });
  }

  void _remove(_EditableCalmResource item) {
    setState(() {
      _items.remove(item);
      item.dispose();
    });
  }

  static String? _urlError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Add a YouTube, Spotify, or web URL';
    final normalized = _normalizeUrl(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid URL';
    }
    return null;
  }

  static String _normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.contains('://')) return value;
    return 'https://$value';
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(calmResourcePreferencesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstRun ? 'Set up Calm' : 'Calm resources'),
        automaticallyImplyLeading: !widget.firstRun,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (preferences) {
          _initialize(preferences);
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _IntroCard(firstRun: widget.firstRun),
                  const SizedBox(height: 16),
                  _ResourceSection(
                    title: 'Mindfulness',
                    subtitle: 'Breathing, grounding, or guided practices.',
                    kind: CalmResourceKind.mindfulness,
                    items: _items,
                    onAdd: () => _add(CalmResourceKind.mindfulness),
                    onRemove: _remove,
                    urlValidator: _urlError,
                  ),
                  const SizedBox(height: 16),
                  _ResourceSection(
                    title: 'Calming music',
                    subtitle: 'Playlists, channels, or low-stimulation sound.',
                    kind: CalmResourceKind.music,
                    items: _items,
                    onAdd: () => _add(CalmResourceKind.music),
                    onRemove: _remove,
                    urlValidator: _urlError,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(widget.firstRun ? 'Finish setup' : 'Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.firstRun});

  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstRun
                  ? 'Choose supports before you need them'
                  : 'Keep Calm resources ready',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'These links appear on the Calm screen as large buttons. Use '
              'resources that are safe, familiar, and low-demand for your '
              'family. You can edit them later from Settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceSection extends StatelessWidget {
  const _ResourceSection({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.urlValidator,
  });

  final String title;
  final String subtitle;
  final CalmResourceKind kind;
  final List<_EditableCalmResource> items;
  final VoidCallback onAdd;
  final ValueChanged<_EditableCalmResource> onRemove;
  final FormFieldValidator<String> urlValidator;

  @override
  Widget build(BuildContext context) {
    final sectionItems = items.where((item) => item.kind == kind).toList();
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            for (final item in sectionItems) ...[
              _ResourceEditor(
                item: item,
                onRemove: () => onRemove(item),
                urlValidator: urlValidator,
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('Add ${kind.label.toLowerCase()}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceEditor extends StatelessWidget {
  const _ResourceEditor({
    required this.item,
    required this.onRemove,
    required this.urlValidator,
  });

  final _EditableCalmResource item;
  final VoidCallback onRemove;
  final FormFieldValidator<String> urlValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: item.label,
          decoration: const InputDecoration(
            labelText: 'Label',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Add a label';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: item.url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'youtube.com/... or spotify.com/...',
            border: OutlineInputBorder(),
          ),
          validator: urlValidator,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
        ),
      ],
    );
  }
}

class _EditableCalmResource {
  _EditableCalmResource({
    required this.id,
    required this.kind,
    required String label,
    required String url,
  }) : label = TextEditingController(text: label),
       url = TextEditingController(text: url);

  factory _EditableCalmResource.fromResource(CalmResource resource) {
    return _EditableCalmResource(
      id: resource.id,
      kind: resource.kind,
      label: resource.label,
      url: resource.url,
    );
  }

  factory _EditableCalmResource.blank(CalmResourceKind kind) {
    return _EditableCalmResource(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      label: '',
      url: '',
    );
  }

  final String id;
  final CalmResourceKind kind;
  final TextEditingController label;
  final TextEditingController url;

  void dispose() {
    label.dispose();
    url.dispose();
  }
}
