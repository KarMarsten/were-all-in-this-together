import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/medications/domain/today_item.dart';
import 'package:were_all_in_this_together/features/medications/presentation/today_providers.dart';
import 'package:were_all_in_this_together/features/medications/presentation/widgets/medication_icon.dart';

/// "Today's doses" — every scheduled dose for today across every
/// Person the user manages.
///
/// Design notes (neurodiversity-affirming):
///
/// * Time-ordered, single column, not grouped into "Morning / Evening"
///   buckets. Buckets require deciding when Morning ends; unambiguous
///   times avoid that cognitive load.
/// * Two primary actions per row: **Taken** and **Skip**. No hidden
///   gestures, no swipe-to-reveal — all affordances are visible.
/// * Past-due doses aren't scolded. They render with a small "earlier
///   today" hint but otherwise look identical to upcoming rows.
/// * Logged rows show their state inline and offer a single **Undo**
///   path so a mis-tap is never sticky.
/// * Medication groups render as expandable bundle rows — one tap to
///   log the whole stack; expand to see member status.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(todayItemsProvider);
    final logsAsync = ref.watch(todayDoseLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDateHeader(ref.watch(todayClockProvider)()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: err.toString()),
            data: (logs) {
              final now = ref.read(todayClockProvider)();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is TodaySoloItem) {
                    return _SoloTile(
                      dose: item.dose,
                      log: logs[identityOfDose(item.dose)],
                      now: now,
                    );
                  }
                  if (item is TodayGroupItem) {
                    return _GroupTile(item: item, logs: logs, now: now);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Human-friendly header like "Saturday, Apr 18". Deliberately
  /// avoids year / timezone clutter.
  static String _formatDateHeader(DateTime now) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = now.toLocal();
    return '${weekdays[local.weekday - 1]}, '
        '${months[local.month - 1]} ${local.day}';
  }
}

class _SoloTile extends ConsumerStatefulWidget {
  const _SoloTile({
    required this.dose,
    required this.log,
    required this.now,
  });

  final ScheduledDose dose;
  final DoseLog? log;
  final DateTime now;

  @override
  ConsumerState<_SoloTile> createState() => _SoloTileState();
}

class _SoloTileState extends ConsumerState<_SoloTile> {
  /// Guards against double-taps while a Taken/Skip/Undo write is in
  /// flight — without this a user hammering the button can produce
  /// two partially-overlapping upserts and surprise the repo.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final localTime = widget.dose.scheduledAt.toLocal();
    final isPast = widget.dose.scheduledAt.isBefore(widget.now);
    final log = widget.log;

    final dose = widget.dose;
    final titleParts = <String>[dose.medicationName];
    if (dose.dose != null && dose.dose!.trim().isNotEmpty) {
      titleParts.add(dose.dose!.trim());
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _LeadingTime(
              localTime: localTime,
              showEarlier: isPast && log == null,
            ),
            MedicationIcon(form: dose.form, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleParts.join(' · '), style: text.titleSmall),
                  Text(
                    dose.personDisplayName,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _actions(log),
          ],
        ),
      ),
    );
  }

  Widget _actions(DoseLog? log) {
    if (log == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TakeButton(busy: _busy, onPressed: () => _record(DoseOutcome.taken)),
          const SizedBox(width: 4),
          _SkipButton(
            busy: _busy,
            onPressed: () => _record(DoseOutcome.skipped),
          ),
        ],
      );
    }
    return _LoggedState(outcome: log.outcome, busy: _busy, onUndo: _undo);
  }

  Future<void> _record(DoseOutcome outcome) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(doseLogRepositoryProvider).record(
            personId: widget.dose.personId,
            medicationId: widget.dose.medicationId,
            scheduledAt: widget.dose.scheduledAt,
            outcome: outcome,
          );
      invalidateDoseLogsState(ref);
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: $err")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(doseLogRepositoryProvider).undo(
            medicationId: widget.dose.medicationId,
            scheduledAt: widget.dose.scheduledAt,
          );
      invalidateDoseLogsState(ref);
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't undo: $err")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Summary of a group bundle's collective state. Derived from the
/// per-member log map rather than stored — we keep the ACK model
/// single-sourced on `dose_logs`.
enum _GroupAckState {
  /// No member of the group has been logged yet.
  none,

  /// Every member is logged as taken.
  allTaken,

  /// Every member is logged as skipped.
  allSkipped,

  /// Some — but not all — members are logged, or the logged set has
  /// a mix of outcomes. The user needs to decide how to finish.
  partial,
}

class _GroupTile extends ConsumerStatefulWidget {
  const _GroupTile({
    required this.item,
    required this.logs,
    required this.now,
  });

  final TodayGroupItem item;
  final Map<DoseIdentity, DoseLog> logs;
  final DateTime now;

  @override
  ConsumerState<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<_GroupTile> {
  bool _busy = false;
  bool _expanded = false;

  _GroupAckState _ackState() {
    var taken = 0;
    var skipped = 0;
    for (final m in widget.item.members) {
      final log = widget.logs[identityOfDose(m)];
      if (log == null) continue;
      if (log.outcome == DoseOutcome.taken) taken += 1;
      if (log.outcome == DoseOutcome.skipped) skipped += 1;
    }
    final total = widget.item.members.length;
    if (taken == 0 && skipped == 0) return _GroupAckState.none;
    if (taken == total) return _GroupAckState.allTaken;
    if (skipped == total) return _GroupAckState.allSkipped;
    return _GroupAckState.partial;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final localTime = widget.item.scheduledAt.toLocal();
    final ack = _ackState();
    final isPast = widget.item.scheduledAt.isBefore(widget.now) &&
        ack == _GroupAckState.none;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: scheme.primaryContainer.withValues(alpha: 0.22),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  _LeadingTime(localTime: localTime, showEarlier: isPast),
                  Icon(Icons.layers_outlined, size: 28, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.groupName, style: text.titleSmall),
                        Text(
                          '${widget.item.personDisplayName} · '
                          '${widget.item.members.length} meds'
                          '${_summaryFor(ack)}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _groupActions(ack),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) const Divider(height: 1),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in widget.item.members)
                    _MemberRow(
                      dose: m,
                      log: widget.logs[identityOfDose(m)],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _summaryFor(_GroupAckState state) {
    switch (state) {
      case _GroupAckState.none:
        return '';
      case _GroupAckState.allTaken:
        return ' · all taken';
      case _GroupAckState.allSkipped:
        return ' · all skipped';
      case _GroupAckState.partial:
        var taken = 0;
        for (final m in widget.item.members) {
          final log = widget.logs[identityOfDose(m)];
          if (log?.outcome == DoseOutcome.taken) taken += 1;
        }
        return ' · $taken / ${widget.item.members.length} logged';
    }
  }

  Widget _groupActions(_GroupAckState state) {
    switch (state) {
      case _GroupAckState.none:
      case _GroupAckState.partial:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TakeButton(
              busy: _busy,
              onPressed: () => _recordAll(DoseOutcome.taken),
            ),
            const SizedBox(width: 4),
            _SkipButton(
              busy: _busy,
              onPressed: () => _recordAll(DoseOutcome.skipped),
            ),
          ],
        );
      case _GroupAckState.allTaken:
        return _LoggedState(
          outcome: DoseOutcome.taken,
          busy: _busy,
          onUndo: _undoAll,
        );
      case _GroupAckState.allSkipped:
        return _LoggedState(
          outcome: DoseOutcome.skipped,
          busy: _busy,
          onUndo: _undoAll,
        );
    }
  }

  Future<void> _recordAll(DoseOutcome outcome) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(doseLogRepositoryProvider);
      // Serial writes rather than Future.wait — keeps the error surface
      // predictable (first failure stops later writes) and avoids the
      // appearance of partial-commit inside a single transaction when
      // there isn't one.
      for (final m in widget.item.members) {
        await repo.record(
          personId: m.personId,
          medicationId: m.medicationId,
          scheduledAt: m.scheduledAt,
          outcome: outcome,
        );
      }
      invalidateDoseLogsState(ref);
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: $err")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undoAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(doseLogRepositoryProvider);
      for (final m in widget.item.members) {
        await repo.undo(
          medicationId: m.medicationId,
          scheduledAt: m.scheduledAt,
        );
      }
      invalidateDoseLogsState(ref);
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't undo: $err")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.dose, required this.log});

  final ScheduledDose dose;
  final DoseLog? log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (log?.outcome) {
      DoseOutcome.taken => (Icons.check_circle, scheme.primary),
      DoseOutcome.skipped => (
          Icons.remove_circle_outline,
          scheme.onSurfaceVariant,
        ),
      null => (Icons.radio_button_unchecked, scheme.onSurfaceVariant),
    };
    final titleParts = <String>[dose.medicationName];
    if (dose.dose != null && dose.dose!.trim().isNotEmpty) {
      titleParts.add(dose.dose!.trim());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              titleParts.join(' · '),
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clock-on-the-left column, shared by solo and group tiles so time
/// positions align vertically across rows in the list.
class _LeadingTime extends StatelessWidget {
  const _LeadingTime({
    required this.localTime,
    required this.showEarlier,
  });

  final DateTime localTime;
  final bool showEarlier;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatClock(localTime),
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (showEarlier)
            Text(
              'earlier',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _TakeButton extends StatelessWidget {
  const _TakeButton({required this.onPressed, required this.busy});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Taken'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed, required this.busy});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: busy ? null : onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('Skip'),
    );
  }
}

class _LoggedState extends StatelessWidget {
  const _LoggedState({
    required this.outcome,
    required this.onUndo,
    required this.busy,
  });

  final DoseOutcome outcome;
  final VoidCallback onUndo;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (icon, label, color) = switch (outcome) {
      DoseOutcome.taken => (
          Icons.check_circle,
          'Taken',
          scheme.primary,
        ),
      DoseOutcome.skipped => (
          Icons.remove_circle_outline,
          'Skipped',
          scheme.onSurfaceVariant,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(label, style: text.labelLarge?.copyWith(color: color)),
        TextButton(
          onPressed: busy ? null : onUndo,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Undo'),
        ),
      ],
    );
  }
}

/// Format a DateTime as 24h "HH:MM". We don't localise to AM/PM here
/// because the user population skews EU; a follow-up can wire up
/// locale-aware time formatting once we introduce `intl`.
String _formatClock(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
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
              Icons.brightness_5_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing scheduled today',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Doses with a daily or weekly schedule will show up here '
              'automatically.',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
              "Couldn't load today's doses",
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
