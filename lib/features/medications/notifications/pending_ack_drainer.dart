import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/core/notifications/pending_ack_queue.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';

/// Drains [PendingAckQueue] into the encrypted Drift DB.
///
/// When the user taps Taken or Skip on a notification action, the
/// background isolate does not have the Person encryption keys
/// needed to write a `DoseLog` row directly. Instead it enqueues a
/// [PendingAck] to SharedPreferences; this drainer — which runs in
/// the main isolate, with Riverpod and key access — converts each
/// entry into a real `DoseLog.record(...)` call and clears the
/// queue.
///
/// Safety properties:
///
/// * `DoseLogRepository.record` upserts on `(medicationId,
///   scheduledAt)`, so a duplicate ACK (e.g. user tapped twice, or
///   foreground + background handler both fired on slow devices)
///   doesn't double-count.
/// * Entries that fail to write (missing Person key, disk error, …)
///   are left in the queue so the next drain can retry. We never
///   blackhole an ACK silently.
class PendingAckDrainer {
  PendingAckDrainer({
    required DoseLogRepository doseLogs,
    required Future<SharedPreferences> Function() preferencesLoader,
  })  : _doseLogs = doseLogs,
        _loadPrefs = preferencesLoader;

  final DoseLogRepository _doseLogs;
  final Future<SharedPreferences> Function() _loadPrefs;

  /// Read the queue, attempt to write each ACK, drop the ones that
  /// succeeded. Returns the number of ACKs actually written — the
  /// caller (usually an app-lifecycle observer) can log that for
  /// diagnostics.
  Future<int> drain() async {
    final prefs = await _loadPrefs();
    final queue = PendingAckQueue(prefs);
    final entries = queue.readAll();
    if (entries.isEmpty) return 0;

    final drained = <PendingAck>[];
    var written = 0;
    for (final ack in entries) {
      final outcome = _parseOutcome(ack.outcome);
      if (outcome == null) {
        // Unknown outcome wire value — probably a future enum we
        // don't know about. Drop it so a stuck entry doesn't block
        // every ACK behind it.
        debugPrint(
          'PendingAckDrainer: dropping ack with unknown outcome '
          '"${ack.outcome}" for ${ack.medicationId}',
        );
        drained.add(ack);
        continue;
      }
      try {
        await _doseLogs.record(
          personId: ack.personId,
          medicationId: ack.medicationId,
          scheduledAt: ack.scheduledAt,
          outcome: outcome,
        );
        written++;
        drained.add(ack);
      } on DoseLogKeyMissingError catch (e) {
        // Person key is gone (device wipe, etc.). The dose log can
        // never be written; drop the entry to avoid an infinite
        // retry loop on every app open.
        debugPrint('PendingAckDrainer: dropping unrecoverable ACK ($e)');
        drained.add(ack);
      } on Object catch (e, st) {
        // Everything else is considered transient. Leave the entry
        // in the queue and move on to the next one.
        debugPrint('PendingAckDrainer: transient failure ($e)');
        debugPrintStack(stackTrace: st);
      }
    }
    if (drained.isNotEmpty) {
      await queue.remove(drained);
    }
    return written;
  }

  /// Wire name → enum. Returns `null` on unknown values so the
  /// drainer can decide whether to drop the entry.
  static DoseOutcome? _parseOutcome(String wire) {
    for (final o in DoseOutcome.values) {
      if (o.name == wire) return o;
    }
    return null;
  }
}

/// Main-isolate [PendingAckDrainer] bound to the real dose-log repo
/// and the real SharedPreferences. Tests override this to supply a
/// fake.
final pendingAckDrainerProvider = Provider<PendingAckDrainer>((ref) {
  return PendingAckDrainer(
    doseLogs: ref.watch(doseLogRepositoryProvider),
    preferencesLoader: SharedPreferences.getInstance,
  );
});
