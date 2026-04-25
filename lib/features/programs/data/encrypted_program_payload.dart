/// JSON inside the programs table `payload` column before encryption.
class EncryptedProgramPayload {
  const EncryptedProgramPayload({
    required this.schemaVersion,
    required this.name,
    this.phone,
    this.contactName,
    this.contactRole,
    this.email,
    this.address,
    this.websiteUrl,
    this.hours,
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
      contactName: json['contactName'] as String?,
      contactRole: json['contactRole'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      hours: json['hours'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String name;
  final String? phone;
  final String? contactName;
  final String? contactRole;
  final String? email;
  final String? address;
  final String? websiteUrl;
  final String? hours;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        if (phone != null) 'phone': phone,
        if (contactName != null) 'contactName': contactName,
        if (contactRole != null) 'contactRole': contactRole,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (hours != null) 'hours': hours,
        if (notes != null) 'notes': notes,
      };
}
