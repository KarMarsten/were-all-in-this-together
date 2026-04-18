import 'package:flutter/material.dart';

import 'package:were_all_in_this_together/core/theme/app_theme.dart';

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
/// v1 shows hard-coded placeholder content. Phase 2 will load the user's
/// personal safety plan from the encrypted local database.
class CalmScreen extends StatelessWidget {
  const CalmScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const _SectionCard(
                    heading: 'Coping strategies',
                    children: [
                      _PlanItem(text: 'Step into another room.'),
                      _PlanItem(text: 'Headphones on, one familiar song.'),
                      _PlanItem(text: 'Text a safe person.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    heading: 'Reasons to stay',
                    children: [
                      _PlanItem(text: 'Placeholder grounding anchor.'),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.heading, required this.children});
  final String heading;
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
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
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

class _CrisisContactsPanel extends StatelessWidget {
  const _CrisisContactsPanel();

  @override
  Widget build(BuildContext context) {
    // TODO(crisis): wire up real tel:/sms: intents once a URL launcher is
    // added. Kept as taps with no handler on purpose — a half-built dialing
    // UX on this screen is worse than none.
    return const _SectionCard(
      heading: 'If you need more help',
      children: [
        _CrisisContactTile(
          label: '988 — Suicide & Crisis Lifeline',
          onTap: null,
        ),
        _CrisisContactTile(
          label: 'Text HOME to 741741 — Crisis Text Line',
          onTap: null,
        ),
        _CrisisContactTile(
          label: 'Your therapist (configure in Settings)',
          onTap: null,
        ),
      ],
    );
  }
}

class _CrisisContactTile extends StatelessWidget {
  const _CrisisContactTile({required this.label, required this.onTap});
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
              Icons.phone_outlined,
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
