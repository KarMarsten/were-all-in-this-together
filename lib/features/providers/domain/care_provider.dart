import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_provider.freezed.dart';

/// Coarse category for a `CareProvider`, used to group and render the
/// list. Deliberately small — five buckets the UI can colour and sort
/// by. Real specialty precision lives in the free-text
/// [CareProvider.specialty] field ("OT", "GI", "speech-language", etc.)
/// so the enum stays stable while clinical detail grows freely.
///
/// `other` intentionally covers anything outside the four named kinds
/// (e.g. a lactation consultant, a school nurse, an academic
/// evaluator). Forcing an edge case into `specialist` would flatten
/// useful distinctions the grouped list cares about.
enum CareProviderKind {
  pcp,
  specialist,
  therapist,
  dentist,
  other;

  /// Stable wire name for encrypted-payload round-trips. Using `name`
  /// directly would couple the serialisation to Dart identifier
  /// stability, which is fine today but makes future renames silently
  /// breaking.
  String get wireName => switch (this) {
        CareProviderKind.pcp => 'pcp',
        CareProviderKind.specialist => 'specialist',
        CareProviderKind.therapist => 'therapist',
        CareProviderKind.dentist => 'dentist',
        CareProviderKind.other => 'other',
      };

  /// Decode a wire name written by any build the app has ever shipped.
  /// Unknown values (e.g. a newer build writing a new kind) fall back
  /// to [CareProviderKind.other] so the row still renders — forward
  /// compatibility matters more than enum precision.
  static CareProviderKind fromWireName(String? s) {
    if (s == null) return CareProviderKind.other;
    for (final value in CareProviderKind.values) {
      if (value.wireName == s) return value;
    }
    return CareProviderKind.other;
  }
}

/// A care provider tracked for a specific Person.
///
/// All sensitive fields are stored encrypted at rest under the owning
/// Person's key; this is the plaintext domain shape callers see after
/// the repository has decrypted the row.
///
/// Scope is per-Person on purpose: a single provider serving two
/// siblings will be entered once per sibling for now. Phase 2 may
/// introduce a shared "household" provider concept once the sync
/// story can represent cross-Person references safely.
@freezed
abstract class CareProvider with _$CareProvider {
  const factory CareProvider({
    /// Client-generated UUID v4. Stable across devices, never reused.
    required String id,

    /// Owning Person's id. Never mutated after creation — moving a
    /// provider between People requires a new row so the AAD / key
    /// binding stays honest.
    required String personId,

    /// Free-form display name. Required — "Dr. Chen", "Park Pediatrics",
    /// "Ms. Alvarez (OT)", whatever the user actually says.
    required String name,

    /// Coarse category; see [CareProviderKind] for why this enum is
    /// deliberately small.
    required CareProviderKind kind,

    /// Metadata propagated from the DB row.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Free-text specialty, e.g. "OT", "developmental pediatrics",
    /// "speech-language". Kept as free text rather than a second enum
    /// so clinical precision can grow without schema changes.
    String? specialty,

    /// Practical role / relationship label for handoffs, e.g.
    /// "medication prescriber", "IEP contact", or "care coordinator".
    String? role,

    /// Named contact when the organization is the provider record.
    String? contactName,

    /// Dialable phone number (free-form — we don't parse or format).
    String? phone,

    /// Email address for the provider / office / portal support.
    String? email,

    /// Fax number for forms, releases, and school / clinic handoffs.
    String? fax,

    /// Single-line address for lookup / navigation. We deliberately do
    /// not structure this — users paste from Contacts and Maps handles
    /// the rest.
    String? address,

    /// Human label for [portalUrl], e.g. "MyChart" or "Therapy portal".
    String? portalLabel,

    /// Patient portal URL. Expected to be `http(s)://…`; validated at
    /// the form layer, not here.
    String? portalUrl,

    /// After-hours dialable number when it differs from [phone].
    String? afterHoursPhone,

    /// Free-text instructions for urgent / after-hours routing.
    String? afterHoursInstructions,

    /// Free-form notes — office hours, receptionist's name, in-network
    /// dates, whatever the user finds worth remembering.
    String? notes,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _CareProvider;
}
