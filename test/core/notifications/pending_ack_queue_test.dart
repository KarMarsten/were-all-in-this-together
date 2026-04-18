import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/core/notifications/pending_ack_queue.dart';

PendingAck _ack({
  String medicationId = 'm1',
  String personId = 'p1',
  int scheduledAtUtcMs = 1_700_000_000_000,
  String outcome = 'taken',
  int? ackedAtUtcMs,
  String source = 'background',
}) {
  return PendingAck(
    medicationId: medicationId,
    personId: personId,
    scheduledAtUtcMs: scheduledAtUtcMs,
    outcome: outcome,
    ackedAtUtcMs: ackedAtUtcMs ?? scheduledAtUtcMs + 1000,
    source: source,
  );
}

void main() {
  late SharedPreferences prefs;
  late PendingAckQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    queue = PendingAckQueue(prefs);
  });

  group('PendingAck JSON', () {
    test('toJson → fromJson preserves every field', () {
      final ack = _ack(source: 'foreground');
      final roundTripped = PendingAck.fromJson(ack.toJson());
      expect(roundTripped.medicationId, ack.medicationId);
      expect(roundTripped.personId, ack.personId);
      expect(roundTripped.scheduledAtUtcMs, ack.scheduledAtUtcMs);
      expect(roundTripped.outcome, ack.outcome);
      expect(roundTripped.ackedAtUtcMs, ack.ackedAtUtcMs);
      expect(roundTripped.source, ack.source);
    });

    test('fromJson rejects a malformed payload', () {
      expect(
        () => PendingAck.fromJson(const {'mid': 42}),
        throwsFormatException,
      );
    });

    test('scheduledAt and ackedAt decode as UTC', () {
      final ack = _ack();
      expect(ack.scheduledAt.isUtc, isTrue);
      expect(ack.ackedAt.isUtc, isTrue);
    });
  });

  group('PendingAckQueue', () {
    test('readAll on a fresh queue returns empty', () {
      expect(queue.readAll(), isEmpty);
    });

    test('enqueue persists and round-trips through a new queue instance',
        () async {
      await queue.enqueue(_ack());
      final reopened = PendingAckQueue(prefs);
      expect(reopened.readAll(), hasLength(1));
      expect(reopened.readAll().first.medicationId, 'm1');
    });

    test('enqueue appends — order is preserved', () async {
      await queue.enqueue(_ack(medicationId: 'a'));
      await queue.enqueue(_ack(medicationId: 'b'));
      await queue.enqueue(_ack(medicationId: 'c'));
      expect(
        queue.readAll().map((a) => a.medicationId).toList(),
        ['a', 'b', 'c'],
      );
    });

    test('remove drops only the matched entries', () async {
      final a = _ack(medicationId: 'a', ackedAtUtcMs: 1);
      final b = _ack(medicationId: 'b', ackedAtUtcMs: 2);
      final c = _ack(medicationId: 'c', ackedAtUtcMs: 3);
      await queue.enqueue(a);
      await queue.enqueue(b);
      await queue.enqueue(c);

      await queue.remove([a, c]);
      final remaining = queue.readAll();
      expect(remaining, hasLength(1));
      expect(remaining.first.medicationId, 'b');
    });

    test('remove with an empty iterable is a no-op', () async {
      await queue.enqueue(_ack());
      await queue.remove(const []);
      expect(queue.readAll(), hasLength(1));
    });

    test('clear empties the queue', () async {
      await queue.enqueue(_ack());
      await queue.enqueue(_ack(medicationId: 'm2'));
      await queue.clear();
      expect(queue.readAll(), isEmpty);
    });

    test('malformed entries are silently dropped, good entries survive',
        () async {
      // Hand-crafted blob: one good entry, one garbage entry.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'notif.pendingAcks.v1':
            '[{"mid":"m1","pid":"p1","tsUtc":1,"outcome":"taken",'
                '"ackedAtUtc":2,"source":"background"},'
                '{"nope":"nope"}]',
      });
      final p = await SharedPreferences.getInstance();
      final q = PendingAckQueue(p);
      expect(q.readAll(), hasLength(1));
      expect(q.readAll().first.medicationId, 'm1');
    });
  });
}
