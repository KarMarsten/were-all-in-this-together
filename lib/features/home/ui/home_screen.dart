import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_avatar.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_switcher_sheet.dart';

/// Home screen.
///
/// Layout:
///   * AppBar — app title + search, settings, and about.
///   * Person banner — active-Person switcher.
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
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutApp(context),
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

void _showAboutApp(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  showAboutDialog(
    context: context,
    applicationName: "We're All In This Together",
    applicationVersion: '0.1.0',
    applicationIcon: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        'assets/images/app_icon.png',
        width: 56,
        height: 56,
      ),
    ),
    applicationLegalese: 'Private, local-first family support.',
    children: [
      const SizedBox(height: 16),
      Text(
        'A private, end-to-end encrypted life-admin app for families '
        'supporting a neurodivergent child, a neurodivergent parent, or both.',
        style: textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      Text(
        'Phase 1 is local-only: People, medications, appointments, providers, '
        'profile, notes, milestones, richer programs, apps & sites, PDFs, '
        'cross-domain search, and Calm tools live on this device.',
        style: textTheme.bodyMedium,
      ),
    ],
  );
}

/// Banner at the top of home that declares who the app is focused on right
/// now, and lets the user switch.
///
/// Three states:
///
/// * **Loading** — shows a neutral skeleton so the layout doesn't jump when
///   the roster resolves (usually too fast to see in practice, but this
///   keeps accessibility scanning stable).
/// * **Empty roster** — calls the user to add the first Person.
/// * **Has active Person** — shows the Person's avatar + name, with a
///   switcher affordance that opens the bottom sheet.
class _PersonBanner extends ConsumerWidget {
  const _PersonBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activeAsync = ref.watch(activePersonProvider);

    final child = activeAsync.when(
      loading: () => const _BannerSkeleton(),
      error: (err, _) => _BannerError(message: err.toString()),
      data: (person) {
        if (person == null) {
          return const _BannerEmpty();
        }
        return _BannerPopulated(
          onSwitch: () => showPersonSwitcherSheet(context),
          child: Row(
            children: [
              PersonAvatar(person: person, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focused on',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      person.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: scheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Switch person',
                icon: Icon(Icons.unfold_more, color: scheme.onPrimaryContainer),
                onPressed: () => showPersonSwitcherSheet(context),
              ),
            ],
          ),
        );
      },
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _BannerPopulated extends StatelessWidget {
  const _BannerPopulated({required this.child, required this.onSwitch});
  final Widget child;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onSwitch,
      child: child,
    );
  }
}

class _BannerEmpty extends StatelessWidget {
  const _BannerEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primary,
          child: Icon(Icons.person_add_alt_1, color: scheme.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's start",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Add the first person',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.push(Routes.personNew),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.3),
          radius: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Loading…',
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline, color: scheme.error),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: scheme.onPrimaryContainer),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _tiles = <_FeatureTileData>[
    _FeatureTileData(
      label: "Today's doses",
      icon: Icons.brightness_5_outlined,
      description: "What's due today",
      route: Routes.today,
    ),
    _FeatureTileData(
      label: 'Appointments',
      icon: Icons.event_outlined,
      description: 'Upcoming visits & reminders',
      route: Routes.appointments,
    ),
    _FeatureTileData(
      label: 'Medications',
      icon: Icons.medication_outlined,
      description: 'Current list + history',
      route: Routes.medications,
    ),
    _FeatureTileData(
      label: 'Profile',
      icon: Icons.psychology_outlined,
      description: 'Stims, routines, what helps',
      route: Routes.profile,
    ),
    _FeatureTileData(
      label: 'Milestones & dates',
      icon: Icons.history_edu_outlined,
      description: 'Diagnoses, shots, milestones',
      route: Routes.milestones,
    ),
    _FeatureTileData(
      label: 'Providers',
      icon: Icons.local_hospital_outlined,
      description: 'Doctors, therapists, specialists',
      route: Routes.careProviders,
    ),
    _FeatureTileData(
      label: 'Programs',
      icon: Icons.school_outlined,
      description: 'Schools, camps, after-care',
      route: Routes.programs,
    ),
    _FeatureTileData(
      label: 'Apps & Sites',
      icon: Icons.link_outlined,
      description: 'Portals, telehealth, IEP tools',
      route: Routes.appsSites,
    ),
    _FeatureTileData(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      description: 'Day-to-day observations',
      route: Routes.notes,
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
    required this.route,
  });
  final String label;
  final IconData icon;
  final String description;
  final String route;
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
        onTap: () => unawaited(context.push(data.route)),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
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
