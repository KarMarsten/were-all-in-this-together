import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/today/domain/today_milestone_item.dart';

Milestone _milestone({
  required String id,
  required DateTime occurredAt,
  MilestonePrecision precision = MilestonePrecision.day,
  DateTime? deletedAt,
}) {
  final created = DateTime.utc(2030);
  return Milestone(
    id: id,
    personId: 'p1',
    kind: MilestoneKind.life,
    title: 'Moved schools',
    occurredAt: occurredAt,
    precision: precision,
    createdAt: created,
    updatedAt: created,
    deletedAt: deletedAt,
  );
}

OwnedTodayMilestone _owned(Milestone m) =>
    OwnedTodayMilestone(milestone: m, personDisplayName: 'Alex');

void main() {
  group('milestoneAnniversaryMatchesToday', () {
    test('matches day precision on same month/day (UTC civil date)', () {
      final now = DateTime(2026, 4, 18, 14);
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2020, 4, 18),
        precision: MilestonePrecision.day,
      );
      expect(
        milestoneAnniversaryMatchesToday(milestone: m, now: now),
        isTrue,
      );
    });

    test('rejects year precision', () {
      final now = DateTime(2026, 1, 1, 12);
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );
      expect(
        milestoneAnniversaryMatchesToday(milestone: m, now: now),
        isFalse,
      );
    });

    test('rejects archived milestones', () {
      final now = DateTime(2026, 4, 18, 12);
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2020, 4, 18),
        deletedAt: DateTime.utc(2026, 1, 1),
      );
      expect(
        milestoneAnniversaryMatchesToday(milestone: m, now: now),
        isFalse,
      );
    });

    test('rejects future calendar dates', () {
      final now = DateTime(2026, 4, 18, 12);
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2027, 4, 18),
        precision: MilestonePrecision.day,
      );
      expect(
        milestoneAnniversaryMatchesToday(milestone: m, now: now),
        isFalse,
      );
    });
  });

  group('milestoneAnniversarySubtitle', () {
    test('pluralises whole years', () {
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2020, 4, 18),
      );
      expect(
        milestoneAnniversarySubtitle(
          milestone: m,
          today: DateTime(2026, 4, 18),
        ),
        '6 years ago',
      );
    });

    test('handles singular year', () {
      final m = _milestone(
        id: '1',
        occurredAt: DateTime.utc(2025, 4, 18),
      );
      expect(
        milestoneAnniversarySubtitle(
          milestone: m,
          today: DateTime(2026, 4, 18),
        ),
        '1 year ago',
      );
    });
  });

  group('expandTodayMilestoneItems', () {
    test('keeps only matching rows and sorts by occurredAt', () {
      final now = DateTime(2026, 4, 18, 9);
      final older = _milestone(
        id: 'older',
        occurredAt: DateTime.utc(2015, 4, 18),
      );
      final newer = _milestone(
        id: 'newer',
        occurredAt: DateTime.utc(2020, 4, 18),
      );
      final wrongDay = _milestone(
        id: 'wrong',
        occurredAt: DateTime.utc(2020, 5, 3),
      );

      final out = expandTodayMilestoneItems(
        milestones: [wrongDay, newer, older].map(_owned),
        now: now,
      );

      expect(out.map((e) => e.milestone.id), ['older', 'newer']);
    });
  });
}
