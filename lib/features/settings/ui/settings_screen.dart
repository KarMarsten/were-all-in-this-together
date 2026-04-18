import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('People'),
            subtitle: Text('Who this app manages'),
          ),
          ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('App lock'),
            subtitle: Text('Face ID / passcode (coming soon)'),
          ),
          ListTile(
            leading: Icon(Icons.sync_outlined),
            title: Text('Sync & co-parent access'),
            subtitle: Text('Phase 2 — end-to-end encrypted'),
          ),
          ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text('Backup & recovery'),
            subtitle: Text('Recovery phrase (coming soon)'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
        ],
      ),
    );
  }
}
