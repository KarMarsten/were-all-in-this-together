import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';

/// Plaintext JSON schema for the sensitive fields of a [DoseLog],
/// before envelope encryption.
///
/// Mirrors the `EncryptedMedicationPayload` pattern: this is the shape
/// that gets `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the
/// owning Person's key, and stored in `dose_logs.payload`.
///
/// **This wire format is forever-compatible.** Every historical `v`
/// value this app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test per
/// version.
///
/// Fields kept *inside* the encryption envelope:
///
/// * `outcome` — taken vs skipped.
/// * `loggedAt` — the exact instant the user tapped. Precise timing
///   is more revealing than the scheduled time (which is already
///   plaintext for query efficiency) because it hints at the user's
///   routine.
/// * `note` — free-text, so obviously encrypted.
///
/// Fields *not* here: `medicationId`, `personId`, `scheduledAt` —
/// they're plaintext columns on the row for query reasons, with the
/// same privacy posture used for medications themselves.
///
/// Schema history:
///
/// * **v1** — outcome + loggedAt + optional note.
class EncryptedDoseLogPayload {
  const EncryptedDoseLogPayload({
    required this.schemaVersion,
    required this.outcome,
    required this.loggedAt,
    this.note,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by an
  /// older build). Throws [FormatException] on missing required fields
  /// and [UnsupportedError] on a version newer than this build.
  factory EncryptedDoseLogPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedDoseLogPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedDoseLogPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedDoseLogPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the '
        'app.',
      );
    }
    final loggedAtRaw = json['loggedAt'];
    if (loggedAtRaw is! String) {
      throw const FormatException(
        'EncryptedDoseLogPayload JSON is missing string "loggedAt"',
      );
    }
    final loggedAt = DateTime.parse(loggedAtRaw);
    if (!loggedAt.isUtc) {
      // Defensive: the wire format is always UTC ISO-8601, but a bad
      // writer could produce local-zone output. Normalise on decode
      // so downstream sort/compare is always UTC-vs-UTC.
      throw FormatException(
        'EncryptedDoseLogPayload.loggedAt must be UTC; got "$loggedAtRaw"',
      );
    }

    final noteRaw = json['note'];
    return EncryptedDoseLogPayload(
      schemaVersion: rawVersion,
      outcome: DoseOutcome.fromWireName(json['outcome'] as String?),
      loggedAt: loggedAt,
      note: noteRaw is String && noteRaw.isNotEmpty ? noteRaw : null,
    );
  }

  /// The schema version written by this build.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DoseOutcome outcome;
  final DateTime loggedAt;
  final String? note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'outcome': outcome.wireName,
        // ISO-8601 UTC. `toIso8601String` on a UTC DateTime always
        // emits the trailing `Z` so decoders can parse it back round
        // to UTC without guessing.
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}
