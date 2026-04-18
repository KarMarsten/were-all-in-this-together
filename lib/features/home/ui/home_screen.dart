import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';

/// Home screen.
///
/// Layout:
///   * AppBar — app title + settings.
///   * Person banner — placeholder (a Person switcher will live here once the
///     data layer exists).
///   * Feature grid — tiles for each main domain.
///   * Persistent "Calm" bar at the bottom, always one tap from dysregulation
///     support.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("We're All In This Together"),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PersonBanner(),
            Expanded(child: _FeatureGrid()),
          ],
        ),
      ),
      bottomNavigationBar: const _CalmBar(),
    );
  }
}

class _PersonBanner extends StatelessWidget {
  const _PersonBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary,
            child: Icon(Icons.person, color: scheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who are we managing?',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  'Demo Person',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Switch person',
            icon: Icon(Icons.unfold_more, color: scheme.onPrimaryContainer),
            onPressed: () {
              // TODO(people): open person switcher bottom sheet.
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _tiles = <_FeatureTileData>[
    _FeatureTileData(
      label: 'Appointments',
      icon: Icons.event_outlined,
      description: 'Upcoming visits & reminders',
    ),
    _FeatureTileData(
      label: 'Medications',
      icon: Icons.medication_outlined,
      description: 'Current list + history',
    ),
    _FeatureTileData(
      label: 'Profile',
      icon: Icons.psychology_outlined,
      description: 'Stims, routines, what helps',
    ),
    _FeatureTileData(
      label: 'Milestones & dates',
      icon: Icons.history_edu_outlined,
      description: 'Diagnoses, shots, milestones',
    ),
    _FeatureTileData(
      label: 'Providers',
      icon: Icons.local_hospital_outlined,
      description: 'Doctors, therapists, specialists',
    ),
    _FeatureTileData(
      label: 'Programs',
      icon: Icons.school_outlined,
      description: 'Schools, camps, after-care',
    ),
    _FeatureTileData(
      label: 'Apps & Sites',
      icon: Icons.link_outlined,
      description: 'Portals, telehealth, IEP tools',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: _tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) => _FeatureTile(data: _tiles[index]),
        );
      },
    );
  }
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.label,
    required this.icon,
    required this.description,
  });
  final String label;
  final IconData icon;
  final String description;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.data});
  final _FeatureTileData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showComingSoon(context, data.label),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 32, color: scheme.primary),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Persistent footer that opens the Calm / safety-plan screen and exposes
/// the People roster.
///
/// Calm stays visually dominant (deliberately — it needs to be reachable in
/// one panicked tap) and People sits next to it as a smaller companion. We
/// resist building this out into a full BottomNavigationBar because Calm is
/// not "a tab"; it's a regulation tool.
class _CalmBar extends StatelessWidget {
  const _CalmBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => context.push(Routes.calm),
                icon: const Icon(Icons.spa_outlined),
                label: const Text('Calm'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.people),
                icon: const Icon(Icons.people_outline),
                label: const Text('People'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
