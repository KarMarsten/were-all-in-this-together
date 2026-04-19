/// JSON inside the programs table `payload` column before encryption.
class EncryptedProgramPayload {
  const EncryptedProgramPayload({
    required this.schemaVersion,
    required this.name,
    this.phone,
    this.notes,
  });

  factory EncryptedProgramPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedProgramPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedProgramPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedProgramPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException(
        'EncryptedProgramPayload JSON is missing "name"',
      );
    }
    return EncryptedProgramPayload(
      schemaVersion: rawVersion,
      name: name,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String name;
  final String? phone;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        if (phone != null) 'phone': phone,
        if (notes != null) 'notes': notes,
      };
}
