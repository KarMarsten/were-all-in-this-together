import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

/// Plaintext JSON schema for the sensitive fields of a `CareProvider`,
/// before envelope encryption.
///
/// Mirrors the contract in `EncryptedPersonPayload` /
/// `EncryptedMedicationPayload`: this is the shape that gets
/// `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the owning
/// Person's key, and stored in the `care_providers.payload` BLOB.
///
/// **This wire format is forever-compatible.** Every historical `v`
/// value the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test per
/// version.
///
/// Schema history:
///
/// * **v1** — name, kind, specialty, phone, address, portalUrl, notes.
class EncryptedCareProviderPayload {
  const EncryptedCareProviderPayload({
    required this.schemaVersion,
    required this.name,
    required this.kind,
    this.specialty,
    this.phone,
    this.address,
    this.portalUrl,
    this.notes,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by an
  /// older build). Throws [FormatException] on missing required fields
  /// and [UnsupportedError] on a version newer than this build.
  factory EncryptedCareProviderPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedCareProviderPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedCareProviderPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedCareProviderPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException(
        'EncryptedCareProviderPayload JSON is missing "name"',
      );
    }
    return EncryptedCareProviderPayload(
      schemaVersion: rawVersion,
      name: name,
      kind: CareProviderKind.fromWireName(json['kind'] as String?),
      specialty: json['specialty'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      portalUrl: json['portalUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// The schema version written by this build. Bump only with a
  /// migration story in `fromJson`.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String name;
  final CareProviderKind kind;
  final String? specialty;
  final String? phone;
  final String? address;
  final String? portalUrl;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        'kind': kind.wireName,
        if (specialty != null) 'specialty': specialty,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (portalUrl != null) 'portalUrl': portalUrl,
        if (notes != null) 'notes': notes,
      };
}
