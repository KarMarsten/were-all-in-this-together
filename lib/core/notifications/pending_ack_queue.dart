import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One caregiver-confirmed dose outcome, waiting to be written into
/// the encrypted DoseLogs table.
///
/// Born in either the foreground or background notification handler;
/// drained by `PendingAckDrainer` on app resume / start. Lives in
/// `SharedPreferences` rather than the Drift DB because the background
/// isolate does not have Person encryption keys, so it cannot
/// construct a proper encrypted `DoseLog` row.
@immutable
class PendingAck {
  const PendingAck({
    required this.medicationId,
    required this.personId,
    required this.scheduledAtUtcMs,
    required this.outcome,
    required this.ackedAtUtcMs,
    required this.source,
  });

  factory PendingAck.fromJson(Map<String, Object?> json) {
    final mid = json['mid'];
    final pid = json['pid'];
    final ts = json['tsUtc'];
    final outcome = json['outcome'];
    final acked = json['ackedAtUtc'];
    final source = json['source'];
    if (mid is! String ||
        pid is! String ||
        ts is! int ||
        outcome is! String ||
        acked is! int ||
        source is! String) {
      throw const FormatException('PendingAck JSON is malformed');
    }
    return PendingAck(
      medicationId: mid,
      personId: pid,
      scheduledAtUtcMs: ts,
      outcome: outcome,
      ackedAtUtcMs: acked,
      source: source,
    );
  }

  final String medicationId;
  final String personId;
  final int scheduledAtUtcMs;

  /// Wire string: `'taken'` or `'skipped'`. Kept as a plain string
  /// so this file doesn't import the medication feature (which
  /// would be a layering violation — `core/` must not depend on
  /// `features/`).
  final String outcome;

  final int ackedAtUtcMs;

  /// `'foreground'` or `'background'` — recorded for diagnostics
  /// only; does not affect how the drainer processes the entry.
  final String source;

  DateTime get scheduledAt =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAtUtcMs, isUtc: true);

  DateTime get ackedAt =>
      DateTime.fromMillisecondsSinceEpoch(ackedAtUtcMs, isUtc: true);

  Map<String, Object?> toJson() => <String, Object?>{
        'mid': medicationId,
        'pid': personId,
        'tsUtc': scheduledAtUtcMs,
        'outcome': outcome,
        'ackedAtUtc': ackedAtUtcMs,
        'source': source,
      };
}

/// Append-only queue of [PendingAck] entries in `SharedPreferences`.
///
/// The queue is a JSON-encoded list stored under a single key.
/// `SharedPreferences.getStringList` would be slightly nicer but
/// encoding as one JSON string gives atomic read / write semantics
/// (one call writes or replaces the whole list), which matters when
/// the background isolate and the foreground drainer race.
class PendingAckQueue {
  const PendingAckQueue(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'notif.pendingAcks.v1';

  /// Read every queued entry. Malformed entries are dropped (and
  /// logged) rather than thrown — a single bad row must not block
  /// every good row behind it.
  List<PendingAck> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <PendingAck>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PendingAck>[];
      final out = <PendingAck>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          out.add(PendingAck.fromJson(Map<String, Object?>.from(entry)));
        } on FormatException catch (e) {
          debugPrint('PendingAckQueue: dropping malformed entry ($e)');
        }
      }
      return out;
    } on FormatException catch (e) {
      debugPrint('PendingAckQueue: queue blob unreadable, clearing ($e)');
      return const <PendingAck>[];
    }
  }

  /// Append [ack] to the queue. Idempotent in the sense that the
  /// drainer deduplicates on `(medicationId, scheduledAtUtcMs)` —
  /// two taps on the same notification (unlikely but possible) will
  /// land as two queue entries but produce one DoseLog upsert.
  Future<void> enqueue(PendingAck ack) async {
    final existing = readAll();
    final next = <PendingAck>[...existing, ack];
    await _write(next);
  }

  /// Remove the supplied entries and persist the remainder.
  /// Matches on all identity fields so we don't accidentally drop
  /// an entry the drainer hasn't processed yet.
  Future<void> remove(Iterable<PendingAck> toDrop) async {
    final drop = {
      for (final a in toDrop)
        _identityKey(a.medicationId, a.scheduledAtUtcMs, a.ackedAtUtcMs),
    };
    if (drop.isEmpty) return;
    final existing = readAll();
    final next = [
      for (final a in existing)
        if (!drop.contains(
          _identityKey(a.medicationId, a.scheduledAtUtcMs, a.ackedAtUtcMs),
        ))
          a,
    ];
    await _write(next);
  }

  /// Drop every entry. Used in tests and for the reset / logout
  /// flow Phase 2 will add.
  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  Future<void> _write(List<PendingAck> entries) async {
    if (entries.isEmpty) {
      await _prefs.remove(_key);
      return;
    }
    await _prefs.setString(
      _key,
      jsonEncode([for (final a in entries) a.toJson()]),
    );
  }

  String _identityKey(String medicationId, int scheduledAt, int ackedAt) {
    return '$medicationId:$scheduledAt:$ackedAt';
  }
}
