import 'package:flutter/material.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Short, list-tile-friendly description of [schedule].
///
/// Returns `null` for [MedicationSchedule.asNeeded] so list tiles can
/// omit the schedule row entirely rather than showing "As needed"
/// everywhere — the absence of a schedule is itself information.
///
/// Examples (24h locale): `"08:00, 20:00"`, `"Mon, Wed, Fri · 09:00"`.
String? medicationScheduleLabel(
  BuildContext context,
  MedicationSchedule schedule,
) {
  if (schedule.kind == ScheduleKind.asNeeded) return null;

  final times = [...schedule.times]
    ..sort(
      (a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
    );
  final timeText = times.isEmpty
      ? 'no times set'
      : times
          .map((t) => TimeOfDay(hour: t.hour, minute: t.minute).format(context))
          .join(', ');

  if (schedule.kind == ScheduleKind.daily) return timeText;

  // Weekly — build a Mon..Sun day list in ISO order.
  const shortDays = <int, String>{
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  final sortedDays = schedule.days.toList()..sort();
  final daysText = sortedDays.map((d) => shortDays[d] ?? '?').join(', ');
  if (sortedDays.length == 7) {
    // All seven days is semantically identical to "daily"; say so rather
    // than listing every day out.
    return timeText;
  }
  return '$daysText · $timeText';
}

/// Inline editor for a [MedicationSchedule].
///
/// Renders three controls stacked vertically:
///
/// 1. A `SegmentedButton` picking the [ScheduleKind].
/// 2. A chip list of times (only when not `asNeeded`) with an "Add time"
///    action.
/// 3. A weekday picker (only when `weekly`).
///
/// All state is pushed to [onChanged] — the parent owns the truth. The
/// editor itself is stateless w.r.t. the schedule, so tests and parent
/// re-renders always see the current value reflected in the widget tree.
///
/// Copy choices deliberately avoid alarm: "As needed" rather than
/// "No schedule", "Specific days" rather than "Custom" to match how
/// real regimens get described.
class MedicationScheduleEditor extends StatelessWidget {
  const MedicationScheduleEditor({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MedicationSchedule value;
  final ValueChanged<MedicationSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<ScheduleKind>(
            segments: const [
              ButtonSegment(
                value: ScheduleKind.asNeeded,
                label: Text('As needed'),
              ),
              ButtonSegment(
                value: ScheduleKind.daily,
                label: Text('Every day'),
              ),
              ButtonSegment(
                value: ScheduleKind.weekly,
                label: Text('Specific days'),
              ),
            ],
            selected: {value.kind},
            onSelectionChanged: (s) => onChanged(_changeKind(s.first)),
          ),
        ),
        if (value.kind != ScheduleKind.asNeeded) ...[
          const SizedBox(height: 16),
          _TimesEditor(
            times: value.times,
            onChanged: (t) => onChanged(value.copyWith(times: t)),
          ),
        ],
        if (value.kind == ScheduleKind.weekly) ...[
          const SizedBox(height: 16),
          _WeekdayPicker(
            days: value.days,
            onChanged: (d) => onChanged(value.copyWith(days: d)),
          ),
        ],
      ],
    );
  }

  /// Transition to [newKind], preserving as much of the current value as
  /// the domain invariants allow.
  ///
  /// * → asNeeded: drop times + days. Times are per-day scheduling state
  ///   that makes no sense without a schedule; asking the user to
  ///   confirm would be fussy.
  /// * → daily: keep times, drop days.
  /// * → weekly: keep times. If no days chosen yet, default to the full
  ///   weekend-inclusive week so the user sees what "weekly" looks like
  ///   and then pares down.
  MedicationSchedule _changeKind(ScheduleKind newKind) {
    switch (newKind) {
      case ScheduleKind.asNeeded:
        return MedicationSchedule.asNeeded;
      case ScheduleKind.daily:
        return MedicationSchedule(
          kind: ScheduleKind.daily,
          times: value.times,
        );
      case ScheduleKind.weekly:
        return MedicationSchedule(
          kind: ScheduleKind.weekly,
          times: value.times,
          days: value.days.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : value.days,
        );
    }
  }
}

class _TimesEditor extends StatelessWidget {
  const _TimesEditor({required this.times, required this.onChanged});

  final List<ScheduledTime> times;
  final ValueChanged<List<ScheduledTime>> onChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = [...times]
      ..sort(
        (a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Times',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text(
            'No times yet. Tap "Add time" to add one.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in sorted)
                InputChip(
                  label: Text(_formatTime(context, t)),
                  onDeleted: () {
                    final next = [...sorted]..remove(t);
                    onChanged(next);
                  },
                ),
            ],
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add_alarm_outlined),
            label: const Text('Add time'),
            onPressed: () => _addTime(context, sorted),
          ),
        ),
      ],
    );
  }

  Future<void> _addTime(
    BuildContext context,
    List<ScheduledTime> currentSorted,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Add reminder time',
    );
    if (picked == null) return;
    final candidate = ScheduledTime(hour: picked.hour, minute: picked.minute);
    // Dedupe so tapping "8:00 AM" twice does nothing silently.
    if (currentSorted.any(
      (t) => t.minutesSinceMidnight == candidate.minutesSinceMidnight,
    )) {
      return;
    }
    onChanged([...currentSorted, candidate]);
  }

  /// Format using the device locale so 12h/24h matches system settings.
  String _formatTime(BuildContext context, ScheduledTime t) {
    return TimeOfDay(hour: t.hour, minute: t.minute).format(context);
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.days, required this.onChanged});

  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;

  /// ISO-8601 week: Monday first. Short single-letter labels match the
  /// convention in calendar headers.
  static const _labels = <({int iso, String short})>[
    (iso: 1, short: 'M'),
    (iso: 2, short: 'T'),
    (iso: 3, short: 'W'),
    (iso: 4, short: 'T'),
    (iso: 5, short: 'F'),
    (iso: 6, short: 'S'),
    (iso: 7, short: 'S'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Days',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final d in _labels)
              FilterChip(
                label: Text(d.short),
                selected: days.contains(d.iso),
                onSelected: (selected) {
                  final next = {...days};
                  if (selected) {
                    next.add(d.iso);
                  } else {
                    next.remove(d.iso);
                  }
                  // We refuse to leave the user with an empty weekday
                  // set — a weekly schedule with zero days is
                  // self-contradictory. Keep at least one selected.
                  if (next.isEmpty) return;
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
