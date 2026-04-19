/// Plaintext JSON schema for the sensitive fields of a `Milestone`,
/// before envelope encryption.
///
/// Mirrors `EncryptedAppointmentPayload`: this is what gets
/// `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the owning
/// Person's key, and stored in the `milestones.payload` BLOB.
///
/// Deliberately omitted fields:
///
/// * `occurredAt`, `precision`, `kind`, `providerId` — plaintext
///   on the row so list screens and future search can operate
///   without a decrypt pass. See `Milestones` table doc for the
///   rationale.
///
/// **This wire format is forever-compatible.** Every historical
/// `v` value the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test
/// per version.
///
/// Schema history:
///
/// * **v1** — title, notes.
class EncryptedMilestonePayload {
  const EncryptedMilestonePayload({
    required this.schemaVersion,
    required this.title,
    this.notes,
  });

  factory EncryptedMilestonePayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedMilestonePayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedMilestonePayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedMilestonePayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final title = json['title'];
    if (title is! String) {
      throw const FormatException(
        'EncryptedMilestonePayload JSON is missing "title"',
      );
    }
    return EncryptedMilestonePayload(
      schemaVersion: rawVersion,
      title: title,
      notes: json['notes'] as String?,
    );
  }

  /// The schema version written by this build. Bump only with a
  /// migration story in `fromJson`.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String title;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'title': title,
        if (notes != null) 'notes': notes,
      };
}
