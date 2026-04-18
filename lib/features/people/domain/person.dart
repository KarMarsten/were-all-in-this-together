import 'package:freezed_annotation/freezed_annotation.dart';

part 'person.freezed.dart';

/// A Person is someone the app tracks data *about* — not someone who logs in
/// (that's a `User`, Phase 2). A Person may or may not correspond to a human
/// who also uses the app.
///
/// All sensitive fields on this model are stored encrypted at rest; [Person]
/// is the plaintext domain shape callers see after the repository has
/// decrypted the row.
@freezed
abstract class Person with _$Person {
  const factory Person({
    /// Client-generated UUID v4. Stable across devices, never reused.
    required String id,

    /// Free-form display name. Required — we need *something* to show in the
    /// picker. May or may not be a legal name.
    required String displayName,

    /// Metadata propagated from the DB row.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Free-form pronouns string. We intentionally do not enumerate choices.
    String? pronouns,

    /// Date of birth, date-only (no time zone).
    DateTime? dob,

    /// Person's own note about how they prefer to be framed — identity-first
    /// vs person-first, community vocabulary preferences, etc. Honoured in
    /// UI copy where we refer to them.
    String? preferredFramingNotes,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Person;
}
