import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';

/// Plaintext JSON schema for the sensitive fields of a `MedicationEvent`,
/// before envelope encryption.
///
/// Mirrors `EncryptedMedicationPayload`'s contract: this shape is
/// `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the owning
/// Person's key, and stored in the `medication_events.payload` BLOB.
///
/// **This wire format is forever-compatible.** Every historical `v`
/// value the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires adding a round-trip test per
/// version.
///
/// Schema history:
///
/// * **v1** — `kind`, optional `note`, and a list of
///   `{field, previous?, current?}` diffs. `occurredAt` lives in
///   plaintext on the row (needed for ordering) so it is *not* in
///   the envelope.
class EncryptedMedicationEventPayload {
  const EncryptedMedicationEventPayload({
    required this.schemaVersion,
    required this.kind,
    this.note,
    this.diffs = const [],
  });

  /// Decode a JSON map previously produced by [toJson], possibly by
  /// an older build. Throws [FormatException] on missing required
  /// fields and [UnsupportedError] on a version newer than this
  /// build understands.
  factory EncryptedMedicationEventPayload.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedMedicationEventPayload JSON is missing integer "v"',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedMedicationEventPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedMedicationEventPayload JSON version $rawVersion is newer '
        'than this build ($currentSchemaVersion); refusing to decode to '
        'avoid silently dropping fields',
      );
    }

    final kindRaw = json['kind'];
    if (kindRaw is! String) {
      throw const FormatException(
        'EncryptedMedicationEventPayload JSON is missing "kind"',
      );
    }

    final rawDiffs = json['diffs'];
    final diffs = <MedicationFieldDiff>[];
    if (rawDiffs is List) {
      for (final entry in rawDiffs) {
        if (entry is! Map) continue;
        final field = entry['field'];
        if (field is! String) continue;
        diffs.add(
          MedicationFieldDiff(
            field: field,
            previous: entry['previous'] as String?,
            current: entry['current'] as String?,
          ),
        );
      }
    }

    return EncryptedMedicationEventPayload(
      schemaVersion: rawVersion,
      kind: MedicationEventKind.fromWireName(kindRaw),
      note: json['note'] as String?,
      diffs: List.unmodifiable(diffs),
    );
  }

  /// Bumped on every additive field. v1 payloads round-trip under v2+
  /// with the new fields left at their defaults.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final MedicationEventKind kind;
  final String? note;

  /// Empty for every kind except [MedicationEventKind.fieldsChanged],
  /// but we don't enforce that here — the decode path is tolerant and
  /// a spurious diff list is harmless.
  final List<MedicationFieldDiff> diffs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'kind': kind.wireName,
        if (note != null) 'note': note,
        if (diffs.isNotEmpty)
          'diffs': [
            for (final d in diffs)
              <String, dynamic>{
                'field': d.field,
                if (d.previous != null) 'previous': d.previous,
                if (d.current != null) 'current': d.current,
              },
          ],
      };
}
