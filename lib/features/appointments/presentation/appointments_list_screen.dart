import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// Appointments list for the currently-active Person.
///
/// Three top-level states (mirrors the Providers list screen):
/// * No active Person → point at "Add someone" first.
/// * Active Person, no appointments → friendly empty state.
/// * Normal list, split into **Upcoming** (soonest first) and a
///   collapsible **Past** section (most recent first). Archived
///   appointments live in their own collapsible section below.
///
/// Date headers ("Today", "Tomorrow", day name, or ISO date) group
/// upcoming visits so the eye lands on when-not-what — which is
/// usually the first question a caregiver is answering when they
/// open this screen.
class AppointmentsListScreen extends ConsumerWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activePersonProvider);
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);
    final archivedAsync = ref.watch(archivedAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: activeAsync.maybeWhen(
          data: (person) => person == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'for ${person.displayName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
          orElse: () => null,
        ),
      ),
      floatingActionButton: activeAsync.maybeWhen(
        data: (person) => person == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.appointmentNew),
                icon: const Icon(Icons.add),
                label: const Text('Add appointment'),
              ),
        orElse: () => null,
      ),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (person) {
          if (person == null) return const _NoActivePersonState();
          return upcomingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (upcoming) {
              final past = pastAsync.value ?? const <Appointment>[];
              final archived =
                  archivedAsync.value ?? const <Appointment>[];
              if (upcoming.isEmpty && past.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  if (upcoming.isNotEmpty)
                    ..._buildUpcomingSection(upcoming)
                  else
                    const _UpcomingPlaceholder(),
                  if (past.isNotEmpty)
                    _CollapsibleList(
                      title: 'Past (${past.length})',
                      appointments: past,
                    ),
                  if (archived.isNotEmpty)
                    _CollapsibleList(
                      title: 'Archived (${archived.length})',
                      appointments: archived,
                      muted: true,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the upcoming section as date-grouped tiles.
  ///
  /// Grouping by calendar day is the natural scan unit for this
  /// list — "what's on my plate Thursday?". Within a day, the repo
  /// already returns items in ascending time so insertion order
  /// here is correct.
  List<Widget> _buildUpcomingSection(List<Appointment> upcoming) {
    final widgets = <Widget>[const _SectionHeader(title: 'Upcoming')];
    DateTime? currentDay;
    for (final appt in upcoming) {
      final local = appt.scheduledAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (currentDay == null || day != currentDay) {
        widgets.add(_DayHeader(day: day));
        currentDay = day;
      }
      widgets.add(_AppointmentTile(appointment: appt));
    }
    return widgets;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.event_outlined,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            formatDayHeader(day),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final local = appointment.scheduledAt.toLocal();
    final subtitle = _subtitleFor(ref);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.event_outlined),
        ),
        title: Text(appointment.title),
        subtitle: Text(
          subtitle == null
              ? formatTime(local)
              : '${formatTime(local)} · $subtitle',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.push(Routes.appointmentEdit(appointment.id)),
      ),
    );
  }

  /// Location · provider-name, whichever the user filled in. We
  /// watch the picker provider rather than calling `findById` so a
  /// provider rename shows up here without an app restart. Works
  /// for archived providers too, since the picker data merges both
  /// lists.
  String? _subtitleFor(WidgetRef ref) {
    final parts = <String>[];
    final location = appointment.location?.trim();
    if (location != null && location.isNotEmpty) {
      parts.add(location);
    }
    final providerId = appointment.providerId;
    if (providerId != null) {
      final pickerAsync =
          ref.watch(careProviderPickerProvider(appointment.personId));
      final name = pickerAsync.whenOrNull(
        data: (data) => _providerDisplayName(data.byId(providerId)),
      );
      if (name != null) parts.add(name);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Keep "(archived)" explicit so historical attribution reads
  /// honestly — "Dr. Chen" is not the same UX as "Dr. Chen
  /// (archived)" when you're deciding which pediatrician saw the
  /// kid.
  String? _providerDisplayName(CareProvider? p) {
    if (p == null) return null;
    if (p.deletedAt != null) return '${p.name} (archived)';
    return p.name;
  }
}

class _CollapsibleList extends StatelessWidget {
  const _CollapsibleList({
    required this.title,
    required this.appointments,
    this.muted = false,
  });

  final String title;
  final List<Appointment> appointments;

  /// Used for the Archived section — pushes the whole card into a
  /// lower-contrast surface so it reads as "less loud".
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        elevation: 0,
        color: muted
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(title),
          children: [
            for (final appt in appointments)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: muted
                      ? scheme.surfaceContainerHigh
                      : scheme.secondaryContainer,
                  foregroundColor: muted
                      ? scheme.onSurfaceVariant
                      : scheme.onSecondaryContainer,
                  child: const Icon(Icons.event_outlined),
                ),
                title: Text(appt.title),
                subtitle: Text(formatDateAndTime(appt.scheduledAt.toLocal())),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(Routes.appointmentEdit(appt.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPlaceholder extends StatelessWidget {
  const _UpcomingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing on the calendar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoActivePersonState extends StatelessWidget {
  const _NoActivePersonState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Add someone first',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Appointments are kept per person, so we need to know who '
              "we're tracking them for.",
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.personNew),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add someone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pediatrician follow-ups, IEP reviews, therapy sessions — '
              'add the visits you want to keep track of.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(Routes.appointmentNew),
              icon: const Icon(Icons.add),
              label: const Text('Add appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load appointments",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Format a local-day [day] (hour/minute/second zeroed) into a
/// human label: "Today", "Tomorrow", day-of-week for this week,
/// ISO date otherwise.
///
/// Free function so widget tests and the form screen can reuse it
/// without reaching into private state. Takes a clock so tests can
/// pin "today" deterministically.
String formatDayHeader(DateTime day, {DateTime Function()? now}) {
  final n = now ?? DateTime.now;
  final today = _stripTime(n());
  final delta = day.difference(today).inDays;
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Tomorrow';
  if (delta > 1 && delta < 7) return _weekdayName(day.weekday);
  // Beyond a week (or in the past, for past lists), an ISO date
  // is the safest label — locale-free, unambiguous, short.
  return _formatIsoDate(day);
}

/// Short, locale-agnostic time ("13:05"). A future l10n pass will
/// swap this for `intl`, but for now a 24h zero-padded string
/// renders predictably in every test and every locale.
String formatTime(DateTime local) {
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// "2026-05-03 · 13:05" — used in the Past / Archived sections,
/// where the collapsible group already groups by section title and
/// a day-header wouldn't add much.
String formatDateAndTime(DateTime local) =>
    '${_formatIsoDate(local)} · ${formatTime(local)}';

String _formatIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

String _weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}
