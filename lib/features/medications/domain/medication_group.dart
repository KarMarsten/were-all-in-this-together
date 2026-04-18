import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

part 'medication_group.freezed.dart';

/// A bundle of medications that are taken together on a shared
/// schedule.
///
/// Example: "Morning stack" might contain Methylphenidate + Vitamin D +
/// Melatonin, all at 08:00 every day. The group fires one reminder and
/// an ACK logs every member as taken at that `scheduledAt`.
///
/// Rules:
///
/// * Scoped to exactly one Person. A group cannot mix meds across
///   people — that would complicate keying (which Person's encryption
///   key?) and user mental model alike.
/// * [memberMedicationIds] references `Medication.id` values belonging
///   to [personId]. Not enforced with a SQL foreign key (same
///   Phase-2-sync-arrival rationale as everywhere else); repositories
///   validate at read time.
/// * A medication may belong to multiple groups. When the same dose
///   instance (same `(medicationId, scheduledAt)`) is rendered twice —
///   once via each group — the existing DoseLog row serves as single
///   source of truth, so ACK'ing any group containing that dose marks
///   it taken everywhere it appears **at that time**. Different times
///   remain independent.
@freezed
abstract class MedicationGroup with _$MedicationGroup {
  const factory MedicationGroup({
    required String id,
    required String personId,
    required String name,
    required MedicationSchedule schedule,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<String>[]) List<String> memberMedicationIds,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _MedicationGroup;
}
