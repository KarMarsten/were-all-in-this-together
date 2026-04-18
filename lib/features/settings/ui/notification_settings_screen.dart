import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';

/// Global reminder-nag defaults. Per-medication overrides live on the
/// medication edit screen; this screen is the fallback those overrides
/// fall back to.
///
/// Surfaces two knobs: how long to wait before re-alerting, and how
/// many times to re-alert at all. The rolling-window reconciler
/// picks these up as soon as we invalidate the prefs provider.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// Local pending edits. We only persist on save — otherwise every
  /// slider drag would fire a reconcile.
  NotificationPreferences? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder nagging')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (saved) {
          final draft = _draft ?? saved;
          final dirty = draft != saved;
          // Reset is enabled whenever the form shows anything other
          // than the out-of-the-box defaults — even if those values
          // are what's stored. Otherwise a user who wants to get back
          // to "vanilla" has no way to without first bumping a chip
          // and then un-bumping it.
          final atDefaults = draft == const NotificationPreferences();
          return _Body(
            draft: draft,
            saving: _saving,
            dirty: dirty,
            onChanged: (next) => setState(() => _draft = next),
            onReset: atDefaults
                ? null
                : () => setState(
                      () => _draft = const NotificationPreferences(),
                    ),
            onSave: dirty ? () => _save(draft) : null,
          );
        },
      ),
    );
  }

  Future<void> _save(NotificationPreferences prefs) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(notificationPreferencesRepositoryProvider);
      await repo.save(prefs);
      ref.invalidate(notificationPreferencesProvider);
      if (!mounted) return;
      setState(() => _draft = null);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't save: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.draft,
    required this.saving,
    required this.dirty,
    required this.onChanged,
    required this.onReset,
    required this.onSave,
  });

  final NotificationPreferences draft;
  final bool saving;
  final bool dirty;
  final ValueChanged<NotificationPreferences> onChanged;
  final VoidCallback? onReset;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionHeader(
            title: 'When a dose is missed',
            subtitle:
                "If nobody taps Taken or Skip on the first reminder, we'll "
                'send follow-ups. These are the defaults — individual '
                'medications can override them in the Edit screen.',
          ),
          const SizedBox(height: 16),
          _IntervalField(
            valueMinutes: draft.nagIntervalMinutes,
            onChanged: (v) => onChanged(draft.copyWith(nagIntervalMinutes: v)),
          ),
          const SizedBox(height: 24),
          _CapField(
            cap: draft.nagCap,
            onChanged: (v) => onChanged(draft.copyWith(nagCap: v)),
          ),
          const SizedBox(height: 32),
          _PreviewBanner(prefs: draft),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving…' : 'Save'),
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: saving ? null : onReset,
            child: const Text('Reset to defaults'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _IntervalField extends StatelessWidget {
  const _IntervalField({required this.valueMinutes, required this.onChanged});

  final int valueMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Present the common values as a discrete picker instead of a
    // free-form slider — people rarely want exactly 23 minutes, and
    // the picker is one glance to read out loud.
    const choices = <int>[1, 5, 10, 15, 30, 60, 120];
    final active = _nearestChoice(valueMinutes, choices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Retry every',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in choices)
              ChoiceChip(
                label: Text(_formatMinutes(c)),
                selected: c == active,
                onSelected: (on) {
                  if (on) onChanged(c);
                },
              ),
          ],
        ),
      ],
    );
  }

  String _formatMinutes(int m) {
    if (m < 60) return '$m min';
    final hours = m ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  int _nearestChoice(int value, List<int> choices) {
    return choices.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
  }
}

String _capLabel(int cap) {
  if (cap == 0) return 'no retries';
  return '$cap ${cap == 1 ? 'retry' : 'retries'}';
}

class _CapField extends StatelessWidget {
  const _CapField({required this.cap, required this.onChanged});

  final int cap;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Up to ${_capLabel(cap)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              'Max ${NotificationPreferences.maxNagCap}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: cap.toDouble(),
          max: NotificationPreferences.maxNagCap.toDouble(),
          divisions: NotificationPreferences.maxNagCap,
          label: '$cap',
          onChanged: (v) => onChanged(v.round()),
        ),
        Text(
          cap == 0
              ? "No follow-ups. A single reminder fires and that's it."
              : 'After the first reminder, send up to $cap follow-up'
                  '${cap == 1 ? '' : 's'}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.prefs});

  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = prefs.nagCap + 1;
    final windowMinutes = prefs.nagCap * prefs.nagIntervalMinutes;
    final windowText = windowMinutes == 0
        ? 'immediately'
        : windowMinutes < 60
            ? 'over $windowMinutes min'
            : 'over ${(windowMinutes / 60).toStringAsFixed(1)} h';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'A missed dose triggers $total notification'
                  '${total == 1 ? '' : 's'} '
                  '$windowText.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              "Couldn't load notification settings.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
