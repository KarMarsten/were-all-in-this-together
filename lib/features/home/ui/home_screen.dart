import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_avatar.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_switcher_sheet.dart';
import 'package:were_all_in_this_together/features/today/domain/today_appointment_item.dart';
import 'package:were_all_in_this_together/features/today/domain/today_item.dart';
import 'package:were_all_in_this_together/features/today/domain/today_milestone_item.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

/// Home screen.
///
/// Layout:
///   * AppBar — app title + search, settings, and about.
///   * Person banner — active-Person switcher.
///   * Today dashboard — active-Person needs first, then secondary actions.
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
            Expanded(child: _HomeDashboard()),
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
        'profile, notes, milestones, linked providers/programs/apps/sites, '
        'PDF care-summary handoffs, ranked search, and Calm tools live on '
        'this device.',
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
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
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

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard();

  static const _actions = <_HomeActionData>[
    _HomeActionData(
      label: 'Medications',
      icon: Icons.medication_outlined,
      description: 'Current meds, schedules, and history',
      route: Routes.medications,
    ),
    _HomeActionData(
      label: 'Appointments',
      icon: Icons.event_outlined,
      description: 'Upcoming visits and reminders',
      route: Routes.appointments,
    ),
    _HomeActionData(
      label: 'Profile',
      icon: Icons.psychology_outlined,
      description: 'What helps, baselines, and routines',
      route: Routes.profile,
    ),
    _HomeActionData(
      label: 'Milestones & dates',
      icon: Icons.history_edu_outlined,
      description: 'Diagnoses, shots, and important dates',
      route: Routes.milestones,
    ),
    _HomeActionData(
      label: 'Providers',
      icon: Icons.local_hospital_outlined,
      description: 'Care-team contacts and portals',
      route: Routes.careProviders,
    ),
    _HomeActionData(
      label: 'Programs',
      icon: Icons.school_outlined,
      description: 'Schools, camps, and after-care',
      route: Routes.programs,
    ),
    _HomeActionData(
      label: 'Apps & Sites',
      icon: Icons.link_outlined,
      description: 'Portals and tools, never passwords',
      route: Routes.appsSites,
    ),
    _HomeActionData(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      description: 'Observations and daily context',
      route: Routes.notes,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePersonAsync = ref.watch(activePersonProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          activePersonAsync.when(
            loading: () => const _TodayNeedsLoading(),
            error: (error, _) => _TodayNeedsError(message: '$error'),
            data: (person) {
              if (person == null) return const _TodayNeedsNoPerson();
              final todayItemsAsync = ref.watch(
                _homeTodayItemsProvider(
                  (personId: person.id, displayName: person.displayName),
                ),
              );
              return todayItemsAsync.when(
                loading: () => const _TodayNeedsLoading(),
                error: (error, _) => _TodayNeedsError(message: '$error'),
                data: (items) {
                  final activeItems = items
                      .where((item) => item.personId == person.id)
                      .toList();
                  return _TodayNeedsCard(
                    personName: person.displayName,
                    items: activeItems,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Other things you may need',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final action in _actions) _HomeActionTile(action: action),
        ],
      ),
    );
  }
}

// Riverpod's family provider type is intentionally inferred; spelling it out
// would expose implementation-heavy generic names without improving call sites.
// ignore: specify_nonobvious_property_types
final _homeTodayItemsProvider =
    FutureProvider.family<
      List<TodayItem>,
      ({String personId, String displayName})
    >((ref, person) async {
      final now = ref.watch(todayClockProvider)();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfTomorrow = startOfDay.add(const Duration(days: 1));

      final meds = await ref
          .watch(medicationRepositoryProvider)
          .listActiveForPerson(person.personId);
      final groups = await ref
          .watch(medicationGroupRepositoryProvider)
          .listActiveForPerson(person.personId);
      final appts = await ref
          .watch(appointmentRepositoryProvider)
          .listForPersonInRange(
            personId: person.personId,
            fromInclusive: startOfDay,
            toExclusive: startOfTomorrow,
          );
      final milestones = await ref
          .watch(milestoneRepositoryProvider)
          .listActiveForPerson(person.personId);

      final medItems = expandTodayItems(
        medications: [
          for (final medication in meds)
            DoseSchedulingContext(
              medication: medication,
              personDisplayName: person.displayName,
            ),
        ],
        groups: [
          for (final group in groups)
            GroupSchedulingContext(
              group: group,
              personDisplayName: person.displayName,
            ),
        ],
        fromInclusive: startOfDay,
        toExclusive: startOfTomorrow,
      );
      final appointmentItems = expandTodayAppointmentItems(
        appointments: [
          for (final appointment in appts)
            OwnedTodayAppointment(
              appointment: appointment,
              personDisplayName: person.displayName,
            ),
        ],
        fromInclusive: startOfDay,
        toExclusive: startOfTomorrow,
      );
      final milestoneItems = expandTodayMilestoneItems(
        milestones: [
          for (final milestone in milestones)
            OwnedTodayMilestone(
              milestone: milestone,
              personDisplayName: person.displayName,
            ),
        ],
        now: now,
      );

      return <TodayItem>[
        ...medItems,
        ...appointmentItems,
        ...milestoneItems,
      ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });

class _HomeActionData {
  const _HomeActionData({
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

class _TodayNeedsCard extends StatelessWidget {
  const _TodayNeedsCard({required this.personName, required this.items});

  final String personName;
  final List<TodayItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meds = items.where(
      (item) => item is TodaySoloItem || item is TodayGroupItem,
    );
    final appointments = items.whereType<TodayAppointmentItem>();
    final milestones = items.whereType<TodayMilestoneItem>();
    final preview = items.take(4).toList();
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Today's needs for $personName",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              items.isEmpty
                  ? 'Nothing scheduled for today. Keep things light.'
                  : 'Start with what is time-sensitive, then come back later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.today),
              icon: const Icon(Icons.brightness_5_outlined),
              label: const Text("Today's doses"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NeedCount(
                    count: meds.length,
                    label: 'Meds',
                    icon: Icons.medication_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NeedCount(
                    count: appointments.length,
                    label: 'Visits',
                    icon: Icons.event_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NeedCount(
                    count: milestones.length,
                    label: 'Dates',
                    icon: Icons.history_edu_outlined,
                  ),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final item in preview) _TodayNeedRow(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeedCount extends StatelessWidget {
  const _NeedCount({
    required this.count,
    required this.label,
    required this.icon,
  });

  final int count;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 6),
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TodayNeedRow extends StatelessWidget {
  const _TodayNeedRow({required this.item});

  final TodayItem item;

  @override
  Widget build(BuildContext context) {
    final summary = _summaryFor(item);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(summary.icon),
      title: Text(summary.title),
      subtitle: Text(summary.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(summary.route),
    );
  }

  ({IconData icon, String title, String subtitle, String route}) _summaryFor(
    TodayItem item,
  ) {
    final local = item.scheduledAt.toLocal();
    final time = _formatTime(local);
    if (item is TodaySoloItem) {
      final dose = item.dose;
      return (
        icon: Icons.medication_outlined,
        title: dose.medicationName,
        subtitle: _joinParts([time, dose.dose]),
        route: Routes.medicationEdit(dose.medicationId),
      );
    }
    if (item is TodayGroupItem) {
      return (
        icon: Icons.medication_liquid_outlined,
        title: item.groupName,
        subtitle: '$time · ${item.members.length} meds',
        route: Routes.medicationGroupEdit(item.groupId),
      );
    }
    if (item is TodayAppointmentItem) {
      return (
        icon: Icons.event_outlined,
        title: item.appointment.title,
        subtitle: _joinParts([time, item.appointment.location]),
        route: Routes.appointmentEdit(item.appointment.id),
      );
    }
    if (item is TodayMilestoneItem) {
      return (
        icon: Icons.history_edu_outlined,
        title: item.milestone.title,
        subtitle: milestoneAnniversarySubtitle(
          milestone: item.milestone,
          today: DateTime(local.year, local.month, local.day),
        ),
        route: Routes.milestoneEdit(item.milestone.id),
      );
    }
    return (
      icon: Icons.check_circle_outline,
      title: 'Today',
      subtitle: time,
      route: Routes.today,
    );
  }

  static String _formatTime(DateTime d) {
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _joinParts(Iterable<String?> parts) {
    return parts
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' · ');
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({required this.action});

  final _HomeActionData action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(action.icon, color: scheme.primary),
        title: Text(action.label),
        subtitle: Text(action.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => unawaited(context.push(action.route)),
      ),
    );
  }
}

class _TodayNeedsLoading extends StatelessWidget {
  const _TodayNeedsLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TodayNeedsNoPerson extends StatelessWidget {
  const _TodayNeedsNoPerson();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add someone first',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              "Today's needs will show here once a person is on the roster.",
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.today),
              icon: const Icon(Icons.brightness_5_outlined),
              label: const Text("Today's doses"),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push(Routes.personNew),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add person'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayNeedsError extends StatelessWidget {
  const _TodayNeedsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
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
