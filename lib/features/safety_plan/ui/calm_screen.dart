import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/core/theme/app_theme.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry_contract.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

/// The Calm / safety-plan screen.
///
/// Design principles (do not soften without conscious reason):
///   * Always reachable in 1 tap from anywhere in the app.
///   * Uses its own dedicated low-stimulation theme (muted, dark, no reds,
///     large tap targets, generous spacing) — applied locally, not globally.
///   * No notifications, badges, or ads ever appear on this screen.
///   * No auth gate — works when the user is dysregulated and can't remember
///     a passcode. (App-lock bypass is intentional on this route.)
///   * Content is intentionally concrete and actionable, not aspirational.
///
/// When someone is focused on Home, **Profile baselines** (communication,
/// sleep, appetite when filled) and **active** structured profile lines
/// surface here — see [calmHasStructuredProfileContent] and
/// [sectionSurfacesOnCalm] for which sections lift out of Profile.
class CalmScreen extends ConsumerWidget {
  const CalmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(activePersonProvider);
    final profileAsync = ref.watch(activePersonProfileProvider);
    final entriesAsync = ref.watch(activeProfileLinesProvider);

    return Theme(
      data: AppTheme.calm(),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Calm'),
              leading: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    'One thing at a time.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  const _SectionCard(
                    heading: 'Right now',
                    children: [
                      _PlanItem(text: 'Slow exhale — longer than your inhale.'),
                      _PlanItem(text: 'Name 5 things you can see.'),
                      _PlanItem(text: 'Cold water on your wrists.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  personAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (person) {
                      if (person == null) {
                        return const SizedBox.shrink();
                      }
                      return profileAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (profile) {
                          return entriesAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (e, st) => const SizedBox.shrink(),
                            data: (entries) {
                              return _CalmPersonProfileStack(
                                personName: person.displayName,
                                profile: profile,
                                entries: entries,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    heading: 'Coping strategies',
                    children: [
                      _PlanItem(
                        text:
                            'Change the channel — water, air, light, or a '
                            'different room.',
                      ),
                      _PlanItem(
                        text:
                            'One sensory anchor: cold water on wrists, a '
                            'weighted blanket, or one familiar song.',
                      ),
                      _PlanItem(
                        text:
                            'Reach one safe person — a short check-in is '
                            'enough.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    heading: 'Reasons to stay',
                    children: [
                      _PlanItem(
                        text:
                            'This pain is real and it can change — you do not '
                            'have to solve everything tonight.',
                      ),
                      _PlanItem(
                        text:
                            'Someone in your life benefits from you being '
                            'here, even when it does not feel that way.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _CrisisContactsPanel(),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                      child: const Text("I'm okay"),
                    ),
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

/// Baselines card plus structured profile blocks for the active person.
class _CalmPersonProfileStack extends StatelessWidget {
  const _CalmPersonProfileStack({
    required this.personName,
    required this.profile,
    required this.entries,
  });

  final String personName;
  final Profile? profile;
  final List<ProfileEntry> entries;

  bool get _hasBaselines {
    final p = profile;
    if (p == null) return false;
    return _nonBlank(p.communicationNotes) ||
        _nonBlank(p.sleepBaseline) ||
        _nonBlank(p.appetiteBaseline);
  }

  static bool _nonBlank(String? s) => s != null && s.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasBaselines && profile != null)
          _CalmBaselinesCard(profile: profile!, personName: personName),
        if (_hasBaselines) const SizedBox(height: 16),
        _CalmProfileBlocks(personName: personName, entries: entries),
      ],
    );
  }
}

/// Free-text baselines from [Profile], same labels as on Profile.
class _CalmBaselinesCard extends StatelessWidget {
  const _CalmBaselinesCard({
    required this.profile,
    required this.personName,
  });

  final Profile profile;
  final String personName;

  @override
  Widget build(BuildContext context) {
    final sections = <({String title, String body})>[];
    void add(String title, String? raw) {
      final body = raw?.trim();
      if (body == null || body.isEmpty) return;
      sections.add((title: title, body: body));
    }

    add('Communication', profile.communicationNotes);
    add('Sleep baseline', profile.sleepBaseline);
    add('Appetite / eating baseline', profile.appetiteBaseline);

    return _SectionCard(
      heading: 'Baselines',
      subtitle: 'From $personName’s profile',
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Text(
            sections[i].title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.85,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            sections[i].body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

/// Profile-backed bullets placed after "Right now".
///
/// [entries] must already be **active-status** rows (e.g. from
/// [activeProfileLinesProvider]).
class _CalmProfileBlocks extends StatelessWidget {
  const _CalmProfileBlocks({
    required this.personName,
    required this.entries,
  });

  final String personName;
  final List<ProfileEntry> entries;

  static int _labelSort(ProfileEntry a, ProfileEntry b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());

  List<ProfileEntry> _sortedInSection(ProfileEntrySection section) {
    return entries.where((e) => e.section == section).toList()
      ..sort(_labelSort);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = 'From $personName’s profile';

    if (!calmHasStructuredProfileContent(entries)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            heading: 'From profile',
            subtitle:
                'Nothing active for $personName yet in sections that show on '
                'Calm — add lines in Profile (or set paused entries back to '
                'active).',
            children: [
              TextButton(
                onPressed: () => context.push(Routes.profile),
                child: const Text('Open Profile'),
              ),
            ],
          ),
        ],
      );
    }

    final helps = _sortedInSection(ProfileEntrySection.whatHelps);
    final signs = _sortedInSection(ProfileEntrySection.earlySign);
    final triggers = _sortedInSection(ProfileEntrySection.trigger);
    final stims = _sortedInSection(ProfileEntrySection.stim);
    final prefs =
        entries.where((e) => calmPreferenceSection(e.section)).toList()
          ..sort((a, b) {
            final ai = calmPreferenceSections.indexOf(a.section);
            final bi = calmPreferenceSections.indexOf(b.section);
            final bySection = ai.compareTo(bi);
            return bySection != 0 ? bySection : _labelSort(a, b);
          });

    final blocks = _sortedInSection(ProfileEntrySection.routineBlock);
    final steps = entries
        .where((e) => e.section == ProfileEntrySection.routineStep)
        .toList()
      ..sort(_labelSort);

    final routineChildren = <Widget>[];
    for (final b in blocks) {
      routineChildren.add(_ProfileEntryPlanItem(entry: b));
      final under = steps
          .where((s) => s.parentEntryId == b.id)
          .toList()
        ..sort(_labelSort);
      for (final s in under) {
        routineChildren.add(
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: _ProfileEntryPlanItem(entry: s),
          ),
        );
      }
    }
    final blockIds = blocks.map((b) => b.id).toSet();
    final orphaned = steps
        .where(
          (s) =>
              s.parentEntryId == null || !blockIds.contains(s.parentEntryId),
        )
        .toList()
      ..sort(_labelSort);
    if (orphaned.isNotEmpty) {
      if (routineChildren.isNotEmpty) {
        routineChildren.add(const SizedBox(height: 8));
      }
      routineChildren.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Routine steps (no block on file)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
      for (final s in orphaned) {
        routineChildren.add(_ProfileEntryPlanItem(entry: s));
      }
    }

    final out = <Widget>[];
    void spacer() {
      if (out.isNotEmpty) out.add(const SizedBox(height: 16));
    }

    void addCard(String heading, List<ProfileEntry> rows) {
      if (rows.isEmpty) return;
      spacer();
      out.add(
        _SectionCard(
          heading: heading,
          subtitle: subtitle,
          children: [for (final e in rows) _ProfileEntryPlanItem(entry: e)],
        ),
      );
    }

    addCard('What helps', helps);
    addCard('Early signs', signs);
    addCard('Triggers', triggers);
    addCard('Stims', stims);
    if (prefs.isNotEmpty) {
      spacer();
      out.add(
        _SectionCard(
          heading: 'Preferences & environment',
          subtitle: subtitle,
          children: [for (final e in prefs) _ProfileEntryPlanItem(entry: e)],
        ),
      );
    }
    if (routineChildren.isNotEmpty) {
      spacer();
      out.add(
        _SectionCard(
          heading: 'Routines',
          subtitle: subtitle,
          children: routineChildren,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: out,
    );
  }
}

class _ProfileEntryPlanItem extends StatelessWidget {
  const _ProfileEntryPlanItem({required this.entry});

  final ProfileEntry entry;

  @override
  Widget build(BuildContext context) {
    final details = entry.details?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.heading,
    required this.children,
    this.subtitle,
  });

  final String heading;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisContactsPanel extends ConsumerWidget {
  const _CrisisContactsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opener = ref.watch(urlOpenerProvider);
    return _SectionCard(
      heading: 'If you need more help',
      children: [
        _CrisisContactTile(
          icon: Icons.phone_outlined,
          label: '988 — Suicide & Crisis Lifeline',
          onTap: () => calmTryLaunch(
            context,
            () => opener.openTel('988'),
            failureMessage: "Couldn't start the call.",
          ),
        ),
        _CrisisContactTile(
          icon: Icons.sms_outlined,
          label: 'Text HOME to 741741 — Crisis Text Line',
          onTap: () => calmTryLaunch(
            context,
            () => opener.openSms('741741', body: 'HOME'),
            failureMessage: "Couldn't open Messages.",
          ),
        ),
        _CrisisContactTile(
          icon: Icons.medical_services_outlined,
          label: 'Care team — open Providers to add a phone',
          onTap: () => context.push(Routes.careProviders),
        ),
      ],
    );
  }
}

class _CrisisContactTile extends StatelessWidget {
  const _CrisisContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Try a URL launcher action; show a floating snackbar on failure.
Future<void> calmTryLaunch(
  BuildContext context,
  Future<bool> Function() action, {
  required String failureMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  try {
    final ok = await action();
    if (!ok && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failureMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } on Exception catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('$failureMessage ($e)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
