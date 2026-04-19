/// Plaintext JSON schema for the sensitive fields of a `Profile`,
/// before envelope encryption.
///
/// This is what gets `jsonEncode`d, UTF-8 encoded, AEAD-encrypted
/// under the owning Person's key, and stored in the `profiles.payload`
/// BLOB.
///
/// **Wire format is forever-compatible.** Bumping
/// [currentSchemaVersion] requires a migration story in `fromJson`
/// and a round-trip test per version.
///
/// Schema history:
///
/// * **v1** — communicationNotes, sleepBaseline, appetiteBaseline.
class EncryptedProfilePayload {
  const EncryptedProfilePayload({
    required this.schemaVersion,
    this.communicationNotes,
    this.sleepBaseline,
    this.appetiteBaseline,
  });

  factory EncryptedProfilePayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedProfilePayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedProfilePayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedProfilePayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    return EncryptedProfilePayload(
      schemaVersion: rawVersion,
      communicationNotes: json['communicationNotes'] as String?,
      sleepBaseline: json['sleepBaseline'] as String?,
      appetiteBaseline: json['appetiteBaseline'] as String?,
    );
  }

  /// The schema version written by this build.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String? communicationNotes;
  final String? sleepBaseline;
  final String? appetiteBaseline;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        if (communicationNotes != null)
          'communicationNotes': communicationNotes,
        if (sleepBaseline != null) 'sleepBaseline': sleepBaseline,
        if (appetiteBaseline != null) 'appetiteBaseline': appetiteBaseline,
      };
}
