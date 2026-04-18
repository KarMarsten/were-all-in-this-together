import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

part 'medication.freezed.dart';

/// The physical form a medication is taken in. Kept small and practical —
/// the goal is to let UI render a sensible icon/label and let filters
/// group similar items, not to be a pharmacological taxonomy.
///
/// `other` covers anything unusual the user wants to track without forcing
/// us to extend the enum on every edge case.
enum MedicationForm {
  pill,
  liquid,
  patch,
  inhaler,
  injection,
  drops,
  cream,
  other;

  /// Stable wire name for encrypted-payload round-trips. Using `name` would
  /// couple the serialisation to Dart identifier stability, which is fine
  /// today but makes future renames silently breaking.
  String get wireName => switch (this) {
        MedicationForm.pill => 'pill',
        MedicationForm.liquid => 'liquid',
        MedicationForm.patch => 'patch',
        MedicationForm.inhaler => 'inhaler',
        MedicationForm.injection => 'injection',
        MedicationForm.drops => 'drops',
        MedicationForm.cream => 'cream',
        MedicationForm.other => 'other',
      };

  static MedicationForm? fromWireName(String? s) {
    if (s == null) return null;
    for (final value in MedicationForm.values) {
      if (value.wireName == s) return value;
    }
    // Unknown value from a newer build: fall back to `other` so the row
    // still renders. We intentionally don't throw — forward compatibility
    // matters more than precision here.
    return MedicationForm.other;
  }
}

/// A medication tracked for a specific Person.
///
/// All sensitive fields are stored encrypted at rest under the owning
/// Person's key; this is the plaintext domain shape callers see after the
/// repository has decrypted the row.
///
/// Naming / framing choices:
///
/// * We use "name" and "dose" as free-form strings rather than structured
///   fields. Real families talk about meds as "half a 10mg tablet at
///   breakfast" — a forced structure loses information.
/// * `startDate` and `endDate` are date-only (UTC midnight) so a regimen
///   that started on a specific calendar day stays on that day across
///   timezones.
/// * There is no "dose unit" field on purpose; it belongs inside [dose].
@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    /// Client-generated UUID v4. Stable across devices, never reused.
    required String id,

    /// Owning Person's id. Never mutated after creation; moving a med
    /// between People requires a new row so the AAD / key binding stays
    /// honest.
    required String personId,

    /// Free-form medication name. Required.
    required String name,

    /// Metadata propagated from the DB row.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Free-form dose description, e.g. "10mg", "5ml in the morning",
    /// "half a tablet". Intentionally unstructured.
    String? dose,

    /// Physical form — pill, liquid, etc. Optional; used mainly for UI
    /// icons.
    MedicationForm? form,

    /// Who prescribed it. Free text today; will link to a Doctor record
    /// in a later PR.
    String? prescriber,

    /// User-visible notes (side effects to watch for, instructions, etc).
    String? notes,

    /// First day of the regimen, date-only.
    DateTime? startDate,

    /// Last day of the regimen, date-only. `null` means ongoing.
    DateTime? endDate,

    /// When and how often to take it. Defaults to
    /// [MedicationSchedule.asNeeded] so meds added before the schedule UI
    /// existed (v1 payloads) decode sensibly without spawning reminders.
    @Default(MedicationSchedule.asNeeded) MedicationSchedule schedule,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Medication;
}
