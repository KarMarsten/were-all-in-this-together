import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// A single OS-level reminder we expect to be scheduled.
///
/// Reminders are derived (pure) from medications + their schedules by
/// `ReminderReconciler`. They are intentionally self-contained — the
/// reconciler diffs "desired" against "pending" without reading any
/// further state.
///
/// `id` is a deterministic 31-bit non-negative hash of the reminder's
/// identity fields. Two runs of the app will compute the same id for
/// the same medication + weekday + time, so reconciliation is
/// stateless.
@immutable
class ScheduledReminder {
  ScheduledReminder({
    required this.medicationId,
    required this.personId,
    required this.medicationName,
    required this.personDisplayName,
    required this.time,
    this.weekday,
    this.dose,
  })  : assert(
          weekday == null || (weekday >= 1 && weekday <= 7),
          'weekday must be null or ISO 1..7',
        ),
        id = _computeId(medicationId, weekday, time);

  /// ISO-8601 weekday (1 = Monday ... 7 = Sunday), or null for a
  /// daily reminder that fires every day at [time].
  final int? weekday;
  final ScheduledTime time;
  final String medicationId;
  final String personId;
  final String medicationName;
  final String personDisplayName;

  /// Optional free-form dose string to include in the notification body.
  final String? dose;

  /// Deterministic OS-level notification id.
  ///
  /// `flutter_local_notifications` requires an `int`; we derive one from
  /// the reminder's identity so the reconciler can diff "pending" vs
  /// "desired" without any side-channel state. Masked to 31 bits to
  /// keep it positive on platforms that treat these as signed.
  final int id;

  static int _computeId(String medicationId, int? weekday, ScheduledTime time) {
    return Object.hash(medicationId, weekday ?? 0, time.hour, time.minute) &
        0x7FFFFFFF;
  }

  /// Human-visible notification title. Keeps the Person's name in front
  /// so a parent watching multiple people's meds sees *whose* reminder
  /// it is at a glance.
  String get title => '$personDisplayName · $medicationName';

  /// Notification body. Includes the dose if we have one so the user
  /// doesn't have to open the app for the most common question
  /// ("how much?"). Time is omitted — iOS shows the current time
  /// alongside notifications natively.
  String get body {
    if (dose == null || dose!.trim().isEmpty) return 'Time for a dose.';
    return 'Time for ${dose!.trim()}.';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledReminder && other.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() =>
      'ScheduledReminder(id=$id, med=$medicationName, '
      'time=${time.toWireString()}, weekday=$weekday)';
}
