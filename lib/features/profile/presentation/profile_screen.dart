import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

/// Living-document baselines and structured entries for the active
/// Person.
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
    _appetite = TextEditingController(
      text: widget.profile.appetiteBaseline ?? '',
    );
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

  /// Status, optional routine parent, optional noted dates (no section
  /// label — used when entries are grouped under a section heading).
  static String _profileEntryGroupedSubtitle(
    ProfileEntry e,
    List<ProfileEntry> entries,
  ) {
    final fmt = DateFormat.yMMMd();
    final parts = <String>[labelForProfileEntryStatus(e.status)];
    if (e.section == ProfileEntrySection.routineStep &&
        e.parentEntryId != null) {
      for (final p in entries) {
        if (p.id == e.parentEntryId &&
            p.section == ProfileEntrySection.routineBlock) {
          parts.add('Under ${p.label}');
          break;
        }
      }
    }
    if (e.firstNoted != null) {
      parts.add('from ${fmt.format(e.firstNoted!.toLocal())}');
    }
    if (e.lastNoted != null) {
      parts.add('to ${fmt.format(e.lastNoted!.toLocal())}');
    }
    return parts.join(' · ');
  }

  List<Widget> _structuredEntrySections(
    BuildContext context,
    List<ProfileEntry> entries,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final titleSmall = Theme.of(context).textTheme.titleSmall;
    final out = <Widget>[];
    for (final section in ProfileEntrySection.values) {
      final inSection = entries.where((e) => e.section == section).toList();
      if (inSection.isEmpty) continue;
      inSection.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
      out
        ..add(const SizedBox(height: 8))
        ..add(
          Text(
            labelForProfileEntrySection(section),
            style: titleSmall?.copyWith(color: scheme.primary),
          ),
        )
        ..add(const SizedBox(height: 4));
      for (final e in inSection) {
        out.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.label),
            subtitle: Text(_profileEntryGroupedSubtitle(e, entries)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.profileEntryEdit(e.id)),
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(activeProfileEntriesProvider);

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
            'These notes are encrypted on this device. Use structured '
            'entries below for stims, preferences, triggers, and similar '
            'lines you want to scan quickly.',
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
              hintText:
                  'Preferred channels, AAC, scripts, '
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
          const SizedBox(height: 32),
          Text(
            'Structured entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.noteNew),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Add a note for the timeline'),
          ),
          const SizedBox(height: 8),
          Text(
            'Quick log when something just happened — separate from the '
            'lines below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          entriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text('Could not load entries: $e'),
            data: (entries) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap an entry to edit. Labels and details are encrypted.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No entries yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else ..._structuredEntrySections(context, entries),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.profileEntryNew),
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
