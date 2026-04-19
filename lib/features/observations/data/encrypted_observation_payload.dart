/// Plaintext JSON stored in the encrypted `observations.payload` blob.
///
/// Schema history:
///
/// * **v1** — label (required), optional notes, optional tags list.
class EncryptedObservationPayload {
  const EncryptedObservationPayload({
    required this.schemaVersion,
    required this.label,
    this.notes,
    this.tags = const <String>[],
  });

  factory EncryptedObservationPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedObservationPayload JSON is missing integer "v"',
      );
    }
    if (rawVersion < 1 || rawVersion > currentSchemaVersion) {
      throw FormatException(
        'EncryptedObservationPayload JSON has invalid "v": $rawVersion',
      );
    }
    final label = json['label'];
    if (label is! String) {
      throw const FormatException(
        'EncryptedObservationPayload JSON is missing "label"',
      );
    }
    final rawTags = json['tags'];
    final tags = <String>[];
    if (rawTags is List<dynamic>) {
      for (final t in rawTags) {
        if (t is String && t.trim().isNotEmpty) {
          tags.add(t.trim());
        }
      }
    }
    return EncryptedObservationPayload(
      schemaVersion: rawVersion,
      label: label,
      notes: json['notes'] as String?,
      tags: tags,
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String label;
  final String? notes;
  final List<String> tags;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': schemaVersion,
    'label': label,
    if (notes != null) 'notes': notes,
    if (tags.isNotEmpty) 'tags': tags,
  };
}
