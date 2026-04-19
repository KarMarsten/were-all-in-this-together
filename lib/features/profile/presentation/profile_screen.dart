import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

/// Living-document baselines for the active Person: communication,
/// sleep, and appetite. Structured sections (stims, routines, etc.)
/// land in follow-up work.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(activePersonProvider);
    final profileAsync = ref.watch(activePersonProfileProvider);

    return personAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(err.toString())),
      ),
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add someone to the roster first — profiles are kept '
                  'per person.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return profileAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(child: Text(err.toString())),
          ),
          data: (profile) {
            if (profile == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _ProfileEditor(
              key: ValueKey(profile.updatedAt.millisecondsSinceEpoch),
              profile: profile,
              personName: person.displayName,
            );
          },
        );
      },
    );
  }
}

class _ProfileEditor extends ConsumerStatefulWidget {
  const _ProfileEditor({
    required this.profile,
    required this.personName,
    super.key,
  });

  final Profile profile;
  final String personName;

  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  late final TextEditingController _communication;
  late final TextEditingController _sleep;
  late final TextEditingController _appetite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _communication = TextEditingController(
      text: widget.profile.communicationNotes ?? '',
    );
    _sleep = TextEditingController(text: widget.profile.sleepBaseline ?? '');
    _appetite =
        TextEditingController(text: widget.profile.appetiteBaseline ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.updatedAt != widget.profile.updatedAt) {
      _communication.text = widget.profile.communicationNotes ?? '';
      _sleep.text = widget.profile.sleepBaseline ?? '';
      _appetite.text = widget.profile.appetiteBaseline ?? '';
    }
  }

  @override
  void dispose() {
    _communication.dispose();
    _sleep.dispose();
    _appetite.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.update(
        widget.profile.copyWith(
          communicationNotes: _nullIfBlank(_communication.text),
          sleepBaseline: _nullIfBlank(_sleep.text),
          appetiteBaseline: _nullIfBlank(_appetite.text),
        ),
      );
      invalidateProfileState(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: $err")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String? _nullIfBlank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile · ${widget.personName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Baselines',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These notes are encrypted on this device. More structured '
            'sections (stims, routines, what helps) will join here in a '
            'later release.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _communication,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Communication',
              hintText: 'Preferred channels, AAC, scripts, '
                  'how to help when stressed…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sleep,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Sleep baseline',
              hintText: 'Typical night pattern, what shifts it…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appetite,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Appetite / eating baseline',
              hintText: 'Typical patterns, safe foods, sensory issues…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
