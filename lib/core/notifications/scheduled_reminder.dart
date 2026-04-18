import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Stable wire values used in a notification payload's `kind` field
/// to distinguish reminder families when both medications and
/// appointments can schedule OS-level notifications.
///
/// Legacy builds (before v7) wrote payloads without `kind` at all;
/// those must continue to decode as [medication]. That backward
/// compatibility is the whole reason for the default.
abstract final class ReminderPayloadKind {
  static const String medication = 'med';
  static const String appointment = 'appt';
}

/// A single, concrete, OS-level notification we expect to be scheduled.
///
/// In contrast to a "recurring" reminder (which the OS fires daily /
/// weekly from one registration), a [ScheduledReminder] is always a
/// **one-shot** fired at a specific [fireAt] wall-clock instant. Every
/// dose instance therefore gets its own reminder id, and every
/// follow-up nag after an unacknowledged dose gets its own id too.
///
/// This shape is what powers:
///
/// * The Taken / Skip action buttons on the notification — the payload
///   carries enough context for the background handler to record a
///   dose log and cancel the remaining nag chain.
/// * Pre-scheduled nag chains: a dose at 08:00 with a 10-minute
///   interval and a cap of 3 produces four reminders (08:00, 08:10,
///   08:20, 08:30), each pointing at the same `scheduledAt` so the
///   handler knows they're the same dose instance.
///
/// Ids are deterministic hashes of `(medicationId, scheduledAtUtcMs,
/// nagIndex)`. The reconciler can therefore diff "pending" vs
/// "desired" across runs without any side-channel state — a reminder
/// the user has already ACK'd becomes a pending id that the next
/// reconciliation pass cancels.
@immutable
class ScheduledReminder {
  ScheduledReminder({
    required this.medicationId,
    required this.personId,
    required this.medicationName,
    required this.personDisplayName,
    required this.scheduledAt,
    required this.fireAt,
    required this.nagIndex,
    required this.totalInChain,
    this.dose,
  })  : assert(nagIndex >= 0, 'nagIndex must be non-negative'),
        assert(
          totalInChain > nagIndex,
          'totalInChain must be strictly greater than nagIndex',
        ),
        assert(scheduledAt.isUtc, 'scheduledAt must be UTC'),
        id = _computeId(medicationId, scheduledAt, nagIndex);

  /// UTC instant of the *original* scheduled dose (nagIndex=0). All
  /// reminders in a nag chain share the same `scheduledAt` even
  /// though their [fireAt] differs.
  final DateTime scheduledAt;

  /// Concrete wall-clock instant the OS should fire this reminder.
  /// For the initial reminder this equals [scheduledAt]; for nag
  /// index `k` it equals `scheduledAt + k * nagInterval`.
  final DateTime fireAt;

  /// `0` for the initial reminder, `1..cap` for follow-ups. Used in
  /// the notification body copy ("reminder 1 of 3") and in the
  /// payload so the handler knows how far along the chain we are.
  final int nagIndex;

  /// Size of the whole nag chain, including the initial reminder.
  /// Present so the notification body can say "reminder 2 of 4"
  /// without the handler having to recompute.
  final int totalInChain;

  final String medicationId;
  final String personId;
  final String medicationName;
  final String personDisplayName;

  /// Optional free-form dose string to include in the notification
  /// body. Same rationale as before — the most common question
  /// ("how much?") answered without opening the app.
  final String? dose;

  /// Deterministic OS-level notification id. Masked to 31 bits to
  /// stay positive on platforms that treat ids as signed.
  final int id;

  /// `true` when this is the first reminder in the chain. Sugar
  /// around `nagIndex == 0`.
  bool get isInitial => nagIndex == 0;

  /// All ids in this dose's nag chain, including this one. Sorted
  /// so the background handler can cancel them deterministically.
  ///
  /// This is computed from the chain metadata rather than stored so
  /// the reconciler doesn't have to thread sibling lists through
  /// every reminder — every participant in the chain can derive it.
  List<int> siblingIds() {
    final ids = <int>[
      for (var i = 0; i < totalInChain; i++)
        _computeId(medicationId, scheduledAt, i),
    ]..sort();
    return ids;
  }

  /// Payload string persisted on the OS notification. Consumed by
  /// the action handler when the user taps Taken / Skip; also
  /// returned when the user taps the notification body.
  ///
  /// We encode explicitly as JSON (rather than a delimited string)
  /// so adding a new field later doesn't break existing in-flight
  /// notifications scheduled by older app versions.
  String encodePayload() {
    return jsonEncode(<String, Object?>{
      'v': 1,
      // `kind` distinguishes medication reminders from the
      // appointment reminders introduced in PR 22. Old builds
      // wrote no `kind` at all; decoders default to `med`, so
      // previously-scheduled reminders still route correctly on
      // upgrade.
      'kind': ReminderPayloadKind.medication,
      'mid': medicationId,
      'pid': personId,
      'tsUtc': scheduledAt.millisecondsSinceEpoch,
      'nag': nagIndex,
      'total': totalInChain,
      'siblings': siblingIds(),
    });
  }

  /// Title shown in the OS banner. Keeps the Person's name in front
  /// so a parent watching multiple people's meds sees *whose*
  /// reminder it is at a glance.
  String get title => '$personDisplayName · $medicationName';

  /// Body line. Appends a nag counter ("reminder 2 of 4") for
  /// follow-ups so the caregiver can tell at a glance whether it's
  /// a fresh dose or a nudge, and how many more nudges are coming.
  String get body {
    final base = (dose == null || dose!.trim().isEmpty)
        ? 'Time for a dose'
        : 'Time for ${dose!.trim()}';
    if (nagIndex == 0) return '$base.';
    return '$base — reminder $nagIndex of ${totalInChain - 1}.';
  }

  static int _computeId(
    String medicationId,
    DateTime scheduledAt,
    int nagIndex,
  ) {
    return Object.hash(
          medicationId,
          scheduledAt.toUtc().millisecondsSinceEpoch,
          nagIndex,
        ) &
        0x7FFFFFFF;
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
      'scheduledAt=$scheduledAt, nag=$nagIndex/$totalInChain)';
}

/// Parsed form of [ScheduledReminder.encodePayload]. Used by the
/// notification action handler to route Taken / Skip taps back to
/// the right dose instance without loading every piece of state a
/// full [ScheduledReminder] carries.
@immutable
class ReminderPayload {
  const ReminderPayload({
    required this.medicationId,
    required this.personId,
    required this.scheduledAtUtcMs,
    required this.nagIndex,
    required this.totalInChain,
    required this.siblingIds,
  });

  /// Decode a JSON-encoded medication payload. Returns `null`
  /// (rather than throwing) on any parse failure, including
  /// payloads whose `kind` marks them as non-medication — the
  /// medication ACK handler should silently ignore appointment
  /// notifications rather than crash on them.
  ///
  /// Notification payloads are the kind of thing we should never
  /// crash on, even if a future build changed the schema
  /// incompatibly.
  static ReminderPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final v = decoded['v'];
      if (v is! int || v < 1) return null;
      // `kind` is absent on payloads written before PR 22; those
      // are all medication reminders. Present-and-not-'med'
      // payloads (e.g. appointment reminders) are not our concern
      // and must not be shoe-horned into a DoseLog.
      final rawKind = decoded['kind'];
      final kind = rawKind is String
          ? rawKind
          : ReminderPayloadKind.medication;
      if (kind != ReminderPayloadKind.medication) return null;
      final mid = decoded['mid'];
      final pid = decoded['pid'];
      final tsUtc = decoded['tsUtc'];
      final nag = decoded['nag'];
      final total = decoded['total'];
      final siblings = decoded['siblings'];
      if (mid is! String || pid is! String) return null;
      if (tsUtc is! int || nag is! int || total is! int) return null;
      if (siblings is! List) return null;
      final sibIds = <int>[];
      for (final s in siblings) {
        if (s is int) sibIds.add(s);
      }
      return ReminderPayload(
        medicationId: mid,
        personId: pid,
        scheduledAtUtcMs: tsUtc,
        nagIndex: nag,
        totalInChain: total,
        siblingIds: List.unmodifiable(sibIds),
      );
    } on FormatException {
      return null;
    }
  }

  final String medicationId;
  final String personId;
  final int scheduledAtUtcMs;
  final int nagIndex;
  final int totalInChain;
  final List<int> siblingIds;

  DateTime get scheduledAt =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAtUtcMs, isUtc: true);
}
