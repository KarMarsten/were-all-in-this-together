import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment.freezed.dart';

/// A single scheduled visit / meeting tracked for a Person.
///
/// Appointments deliberately aren't recurring in this first cut —
/// pediatrician follow-ups, IEP meetings, and therapy sessions vary
/// enough session to session that recurring templates would
/// under-serve the actual use case. A future PR may add a
/// `recurrenceRule` when a concrete need emerges.
///
/// Linking: [providerId] is a soft reference to a `CareProvider`
/// row (same pattern as `Medication.prescriberId`). Archived
/// providers still resolve, so historical appointments keep their
/// attribution even after the provider is retired. An appointment
/// without a linked provider is fine — "School meeting", "family
/// therapy with the three of us", "flu shot at the pharmacy".
///
/// All sensitive fields are stored encrypted at rest under the
/// owning Person's key; this is the plaintext domain shape callers
/// see after the repository has decrypted the row. [scheduledAt]
/// is the one exception, stored in the clear on the row — see
/// `Appointments` table doc for why.
@freezed
abstract class Appointment with _$Appointment {
  const factory Appointment({
    /// Client-generated UUID v4. Stable across devices, never reused.
    required String id,

    /// Owning Person's id. Never mutated after creation — moving
    /// an appointment between People requires a new row so the AAD
    /// / key binding stays honest.
    required String personId,

    /// Free-form title. Required — "Dr. Chen — flu shot",
    /// "IEP review", "OT session".
    required String title,

    /// When the appointment starts (UTC instant).
    required DateTime scheduledAt,

    /// Metadata propagated from the DB row.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Optional link to a `CareProvider`. Kept as a soft id rather
    /// than an embedded provider snapshot so provider edits
    /// (renames, phone changes) are reflected immediately in every
    /// appointment that links to them.
    String? providerId,

    /// Where the visit happens — free-text on purpose. Users paste
    /// from Contacts / Maps / emails; any structure we imposed
    /// would immediately be wrong for telehealth, school visits,
    /// "Dr. Chen's office but the new suite".
    String? location,

    /// How long it's expected to run. Optional because "some time
    /// in the afternoon" is a real level of knowledge.
    int? durationMinutes,

    /// Free-form notes — questions to ask, docs to bring, insurance
    /// details, anything the user wants in their pocket during the
    /// visit.
    String? notes,

    /// How many minutes before [scheduledAt] to surface a local
    /// reminder notification. Stored now, wired to the notification
    /// system in a later PR. `null` means no reminder.
    int? reminderLeadMinutes,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Appointment;
}
