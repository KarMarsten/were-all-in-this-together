import 'package:were_all_in_this_together/features/medications/domain/medication.dart';

/// Plaintext JSON schema for the sensitive fields of a Medication, before
/// envelope encryption.
///
/// Mirrors the contract in `EncryptedPersonPayload`: this is the shape
/// that gets `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the
/// owning Person's key, and stored in the `medications.payload` BLOB.
///
/// **This wire format is forever-compatible.** Every historical `v` value
/// the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test per
/// version.
class EncryptedMedicationPayload {
  const EncryptedMedicationPayload({
    required this.schemaVersion,
    required this.name,
    this.dose,
    this.form,
    this.prescriber,
    this.notes,
    this.startDate,
    this.endDate,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by an
  /// older build). Throws [FormatException] on missing required fields
  /// and [UnsupportedError] on a version newer than this build.
  factory EncryptedMedicationPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedMedicationPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedMedicationPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedMedicationPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException(
        'EncryptedMedicationPayload JSON is missing "name"',
      );
    }
    final startRaw = json['startDate'];
    final endRaw = json['endDate'];
    return EncryptedMedicationPayload(
      schemaVersion: rawVersion,
      name: name,
      dose: json['dose'] as String?,
      form: MedicationForm.fromWireName(json['form'] as String?),
      prescriber: json['prescriber'] as String?,
      notes: json['notes'] as String?,
      startDate: startRaw is String ? _parseDateOnly(startRaw) : null,
      endDate: endRaw is String ? _parseDateOnly(endRaw) : null,
    );
  }

  /// Parse a `YYYY-MM-DD` string as a UTC midnight instant. Same rationale
  /// as on `EncryptedPersonPayload` — preserve the calendar date across
  /// timezones.
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

  /// The schema version written by this build.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String name;
  final String? dose;
  final MedicationForm? form;
  final String? prescriber;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        if (dose != null) 'dose': dose,
        if (form != null) 'form': form!.wireName,
        if (prescriber != null) 'prescriber': prescriber,
        if (notes != null) 'notes': notes,
        if (startDate != null) 'startDate': _dateOnly(startDate!),
        if (endDate != null) 'endDate': _dateOnly(endDate!),
      };

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
