import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// A single one-shot OS notification that announces an upcoming
/// appointment.
///
/// Deliberately simpler than `ScheduledReminder`:
///
/// * No nag chain — if a caregiver misses the alert, they'll see
///   the appointment in the Upcoming list; nagging about a visit
///   that already started is more annoying than useful.
/// * No action buttons — there's nothing to acknowledge in the
///   background. A body tap brings the app to the foreground; the
///   user navigates to the appointment themselves. (A future PR
///   can wire deep-linking straight to the edit screen.)
///
/// The id is derived deterministically from `appointmentId` alone:
///
/// * Same id across edits means rescheduling just replaces the
///   OS-level entry, no cancel-then-reschedule dance.
/// * Different id from any `ScheduledReminder.id` (salted with
///   `'appt'`) so they don't collide in the 31-bit id space.
@immutable
class AppointmentReminder {
  AppointmentReminder({
    required this.appointmentId,
    required this.personId,
    required this.personDisplayName,
    required this.title,
    required this.scheduledAt,
    required this.fireAt,
    this.location,
    this.leadMinutes,
  })  : assert(scheduledAt.isUtc, 'scheduledAt must be UTC'),
        assert(fireAt.isUtc, 'fireAt must be UTC'),
        id = _computeId(appointmentId);

  /// Appointment row this reminder announces.
  final String appointmentId;

  final String personId;
  final String personDisplayName;

  /// User-facing appointment title ("Dr. Chen — flu shot"). Copied
  /// into the notification body so the caregiver doesn't need to
  /// open the app to know what's coming.
  final String title;

  /// UTC instant the appointment is scheduled to start. Used in
  /// the notification body ("in 30 min"), and carried in the
  /// payload for any future deep-link handling.
  final DateTime scheduledAt;

  /// UTC instant the OS should fire the notification. Equals
  /// `scheduledAt - Duration(minutes: leadMinutes)`.
  final DateTime fireAt;

  /// Where the visit happens — appended to the notification body
  /// when present.
  final String? location;

  /// How many minutes before [scheduledAt] the reminder fires.
  /// Purely cosmetic for body copy; the actual fire time is
  /// [fireAt]. Kept on the reminder so the reconciler doesn't
  /// have to do arithmetic twice.
  final int? leadMinutes;

  /// Deterministic OS-level notification id, masked to 31 bits to
  /// stay positive on platforms that treat ids as signed.
  final int id;

  /// Banner title shown by the OS. Person first so a parent
  /// watching multiple People knows *whose* visit it is at a
  /// glance.
  String get displayTitle => '$personDisplayName · $title';

  /// Notification body. "In 30 min · Dr. Chen's office" reads
  /// clearly on the lock screen without the user having to remember
  /// what time the appointment actually was.
  String get body {
    final lead = _formatLead(leadMinutes);
    final trimmedLocation = location?.trim();
    final parts = <String>[
      ?lead,
      if (trimmedLocation != null && trimmedLocation.isNotEmpty)
        trimmedLocation,
    ];
    if (parts.isEmpty) return 'Upcoming appointment';
    return parts.join(' · ');
  }

  static String? _formatLead(int? minutes) {
    if (minutes == null) return null;
    if (minutes <= 0) return 'Starting now';
    if (minutes < 60) return 'In $minutes min';
    if (minutes == 60) return 'In 1 hour';
    if (minutes == 1440) return 'Tomorrow';
    if (minutes % 60 == 0) return 'In ${minutes ~/ 60} hours';
    return 'In $minutes min';
  }

  /// Payload string persisted on the OS notification. Consumed by
  /// [AppointmentReminderPayload.tryDecode] when (a future PR
  /// wires) a tap brings the user to the right appointment.
  ///
  /// Encoded as JSON so a later schema change doesn't break
  /// in-flight notifications scheduled by an older build.
  String encodePayload() {
    return jsonEncode(<String, Object?>{
      'v': 1,
      'kind': ReminderPayloadKind.appointment,
      'aid': appointmentId,
      'pid': personId,
      'tsUtc': scheduledAt.millisecondsSinceEpoch,
    });
  }

  static int _computeId(String appointmentId) {
    // Salt with `'appt'` so the id space is disjoint from
    // `ScheduledReminder._computeId` (which hashes medicationId +
    // scheduledAt + nagIndex). A 31-bit collision is still
    // possible in principle but astronomically unlikely for the
    // cardinalities a single household will ever hit.
    return Object.hash(appointmentId, 'appt') & 0x7FFFFFFF;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentReminder && other.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() =>
      'AppointmentReminder(id=$id, title=$title, fireAt=$fireAt)';
}

/// Parsed form of [AppointmentReminder.encodePayload]. Exists so
/// a tap handler in a later PR can resolve `appointmentId` back to
/// a row without carrying the full reminder through.
@immutable
class AppointmentReminderPayload {
  const AppointmentReminderPayload({
    required this.appointmentId,
    required this.personId,
    required this.scheduledAtUtcMs,
  });

  /// Decode a JSON-encoded payload. Returns `null` on any parse
  /// failure, including payloads whose `kind` marks them as
  /// medication reminders — routing code should silently skip
  /// those rather than throw.
  static AppointmentReminderPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final v = decoded['v'];
      if (v is! int || v < 1) return null;
      final kind = decoded['kind'];
      if (kind != ReminderPayloadKind.appointment) return null;
      final aid = decoded['aid'];
      final pid = decoded['pid'];
      final tsUtc = decoded['tsUtc'];
      if (aid is! String || pid is! String) return null;
      if (tsUtc is! int) return null;
      return AppointmentReminderPayload(
        appointmentId: aid,
        personId: pid,
        scheduledAtUtcMs: tsUtc,
      );
    } on FormatException {
      return null;
    }
  }

  final String appointmentId;
  final String personId;
  final int scheduledAtUtcMs;

  DateTime get scheduledAt =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAtUtcMs, isUtc: true);
}

/// Light-weight inspection of a raw payload's `kind` field without
/// fully parsing it. Used by `NotificationService` implementations
/// to bucket pending notifications by family when diffing the OS
/// queue against desired reminders.
///
/// Returns [ReminderPayloadKind.medication] for payloads that
/// pre-date PR 22 (no `kind` field at all), matching the decoder
/// semantics in [ReminderPayload.tryDecode]. Returns `null` when
/// the payload is absent or malformed beyond our wire contract.
String? peekReminderPayloadKind(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final kind = decoded['kind'];
    if (kind is String) return kind;
    // Legacy (pre-kind) payloads are all medication reminders by
    // definition — no other family existed when they were written.
    return ReminderPayloadKind.medication;
  } on FormatException {
    return null;
  }
}
