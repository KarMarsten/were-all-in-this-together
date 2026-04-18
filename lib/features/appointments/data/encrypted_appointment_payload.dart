/// Plaintext JSON schema for the sensitive fields of an `Appointment`,
/// before envelope encryption.
///
/// Mirrors the contract in `EncryptedCareProviderPayload` /
/// `EncryptedMedicationPayload`: this is the shape that gets
/// `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the owning
/// Person's key, and stored in the `appointments.payload` BLOB.
///
/// Deliberately omitted fields:
///
/// * `scheduledAt` — plaintext on the row (see `Appointments` table
///   doc). Including it here would make it recoverable two ways,
///   and let the two copies silently drift out of sync.
///
/// **This wire format is forever-compatible.** Every historical `v`
/// value the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test per
/// version.
///
/// Schema history:
///
/// * **v1** — title, providerId, location, durationMinutes, notes,
///   reminderLeadMinutes.
class EncryptedAppointmentPayload {
  const EncryptedAppointmentPayload({
    required this.schemaVersion,
    required this.title,
    this.providerId,
    this.location,
    this.durationMinutes,
    this.notes,
    this.reminderLeadMinutes,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by
  /// an older build). Throws [FormatException] on missing required
  /// fields and [UnsupportedError] on a version newer than this
  /// build.
  factory EncryptedAppointmentPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedAppointmentPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedAppointmentPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedAppointmentPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final title = json['title'];
    if (title is! String) {
      throw const FormatException(
        'EncryptedAppointmentPayload JSON is missing "title"',
      );
    }
    return EncryptedAppointmentPayload(
      schemaVersion: rawVersion,
      title: title,
      providerId: json['providerId'] as String?,
      location: json['location'] as String?,
      durationMinutes: _readInt(json, 'durationMinutes'),
      notes: json['notes'] as String?,
      reminderLeadMinutes: _readInt(json, 'reminderLeadMinutes'),
    );
  }

  /// JSON numbers arrive as `int` or `double` depending on the
  /// encoder (Dart's `jsonDecode` preserves the source type). We
  /// coerce once here so the rest of the app sees plain `int?`.
  static int? _readInt(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  /// The schema version written by this build. Bump only with a
  /// migration story in `fromJson`.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String title;
  final String? providerId;
  final String? location;
  final int? durationMinutes;
  final String? notes;
  final int? reminderLeadMinutes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'title': title,
        if (providerId != null) 'providerId': providerId,
        if (location != null) 'location': location,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (reminderLeadMinutes != null)
          'reminderLeadMinutes': reminderLeadMinutes,
      };
}
