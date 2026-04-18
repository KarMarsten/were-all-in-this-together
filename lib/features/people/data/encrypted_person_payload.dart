/// Plaintext JSON schema for the sensitive fields of a Person, before
/// envelope encryption.
///
/// This is the shape that gets `jsonEncode`d, UTF-8 encoded, AEAD-encrypted
/// under the Person's key, and stored in the `persons.payload` BLOB (and,
/// in Phase 2, uploaded to the sync backend).
///
/// **This wire format is forever-compatible.** Every old row on every
/// existing device uses whatever schema was emitted when it was written, so:
///
///   1. The `v` field is mandatory and must always be present on write.
///   2. `fromJson` must know how to read every `v` value the app has ever
///      emitted, possibly by performing in-memory upgrade to the current
///      schema on read.
///   3. Bumping [currentSchemaVersion] requires an ADR and a round-trip test
///      for each historical version.
class EncryptedPersonPayload {
  const EncryptedPersonPayload({
    required this.schemaVersion,
    required this.displayName,
    this.pronouns,
    this.dob,
    this.preferredFramingNotes,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by an
  /// older build of the app). Throws [FormatException] on missing required
  /// fields and [UnsupportedError] on a version newer than this build.
  factory EncryptedPersonPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedPersonPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedPersonPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedPersonPayload JSON "v"=$rawVersion is newer than this '
        'build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final displayName = json['displayName'];
    if (displayName is! String) {
      throw const FormatException(
        'EncryptedPersonPayload JSON is missing "displayName"',
      );
    }
    final dobRaw = json['dob'];
    return EncryptedPersonPayload(
      schemaVersion: rawVersion,
      displayName: displayName,
      pronouns: json['pronouns'] as String?,
      dob: dobRaw is String ? _parseDateOnly(dobRaw) : null,
      preferredFramingNotes: json['preferredFramingNotes'] as String?,
    );
  }

  /// Parse a `YYYY-MM-DD` string as a UTC midnight instant. Using UTC
  /// deliberately: we want the calendar date to be preserved across devices
  /// in different time zones, so dob round-trips losslessly.
  static DateTime _parseDateOnly(String s) {
    final parts = s.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date-only string: "$s"');
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      throw FormatException('Invalid date-only string: "$s"');
    }
    return DateTime.utc(y, m, d);
  }

  /// The schema version written by this build. Bump only with a migration
  /// story in `fromJson`.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String displayName;
  final String? pronouns;

  /// Date-only; serialised as ISO-8601 `YYYY-MM-DD` with no time/zone.
  final DateTime? dob;

  final String? preferredFramingNotes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'displayName': displayName,
        if (pronouns != null) 'pronouns': pronouns,
        if (dob != null) 'dob': _dateOnly(dob!),
        if (preferredFramingNotes != null)
          'preferredFramingNotes': preferredFramingNotes,
      };

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
