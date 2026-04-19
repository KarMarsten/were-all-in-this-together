import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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
}
