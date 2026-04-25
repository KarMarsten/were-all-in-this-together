import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/core/theme/theme_mode_preference.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModePreferenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          themeModeAsync.when(
            loading: () => const ListTile(
              leading: Icon(Icons.contrast_outlined),
              title: Text('Appearance'),
              subtitle: Text('Loading...'),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.contrast_outlined),
              title: const Text('Appearance'),
              subtitle: Text("Couldn't load appearance: $error"),
            ),
            data: (preference) => _AppearanceTile(
              preference: preference,
              onChanged: (next) => _saveThemeMode(context, ref, next),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('People'),
            subtitle: Text('Who this app manages'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Reminder nagging'),
            subtitle: const Text(
              'How often we re-alert, how many times',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.notificationSettings),
          ),
          ListTile(
            leading: const Icon(Icons.spa_outlined),
            title: const Text('Calm resources'),
            subtitle: const Text(
              'Mindfulness and music links shown on the Calm screen',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.calmResources),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Care summary (PDF)'),
            subtitle: const Text(
              'Handoff for babysitters, grandparents, and respite',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.careSummary),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('App lock'),
            subtitle: Text('Face ID / passcode (coming soon)'),
          ),
          const ListTile(
            leading: Icon(Icons.sync_outlined),
            title: Text('Sync & co-parent access'),
            subtitle: Text('Phase 2 — end-to-end encrypted'),
          ),
          const ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text('Backup & recovery'),
            subtitle: Text('Recovery phrase (coming soon)'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveThemeMode(
    BuildContext context,
    WidgetRef ref,
    AppThemeModePreference preference,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(themeModePreferenceRepositoryProvider);
      await repo.save(preference);
      ref.invalidate(themeModePreferenceProvider);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't save appearance: $error"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.preference,
    required this.onChanged,
  });

  final AppThemeModePreference preference;
  final ValueChanged<AppThemeModePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contrast_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a lower-glare dark mode, keep the light theme, or '
                'follow your device setting.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SegmentedButton<AppThemeModePreference>(
                segments: [
                  for (final option in AppThemeModePreference.values)
                    ButtonSegment(
                      value: option,
                      label: Text(option.label),
                      tooltip: option.description,
                    ),
                ],
                selected: {preference},
                onSelectionChanged: (selection) {
                  final next = selection.single;
                  if (next != preference) onChanged(next);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
