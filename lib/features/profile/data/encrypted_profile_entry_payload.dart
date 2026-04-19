/// Plaintext JSON for `ProfileEntry` fields stored in the encrypted
/// `profile_entries.payload` blob.
///
/// Schema history:
///
/// * **v1** — label (required), optional details.
class EncryptedProfileEntryPayload {
  const EncryptedProfileEntryPayload({
    required this.schemaVersion,
    required this.label,
    this.details,
  });

  factory EncryptedProfileEntryPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedProfileEntryPayload JSON is missing integer "v"',
      );
    }
    if (rawVersion < 1 || rawVersion > currentSchemaVersion) {
      throw FormatException(
        'EncryptedProfileEntryPayload JSON has invalid "v": $rawVersion',
      );
    }
    final label = json['label'];
    if (label is! String) {
      throw const FormatException(
        'EncryptedProfileEntryPayload JSON is missing "label"',
      );
    }
    return EncryptedProfileEntryPayload(
      schemaVersion: rawVersion,
      label: label,
      details: json['details'] as String?,
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String label;
  final String? details;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': schemaVersion,
    'label': label,
    if (details != null) 'details': details,
  };
}
