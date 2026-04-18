import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Plaintext JSON shape that becomes the encrypted `payload` blob on
/// a `MedicationGroups` row.
///
/// Why this is encrypted at all: the group's name ("Morning meds",
/// "Anti-seizure stack") is as revealing as a medication name, and
/// the member ID list — paired with an attacker's view of the
/// `medications.personId` column — lets someone infer "these meds are
/// taken together" even without decrypting the meds themselves.
///
/// **Forever-compatible wire format.** Any `v` we've ever emitted must
/// stay decodable; bumping [currentSchemaVersion] requires an ADR and
/// a per-version round-trip test.
///
/// Schema history:
///
/// * **v1** — name, schedule, members.
class EncryptedMedicationGroupPayload {
  const EncryptedMedicationGroupPayload({
    required this.schemaVersion,
    required this.name,
    required this.schedule,
    required this.memberMedicationIds,
  });

  /// Decode a JSON map previously produced by `toJson`. Throws
  /// [FormatException] for missing required fields and [UnsupportedError]
  /// when `v` is newer than this build — same semantics as the other
  /// encrypted payloads in this module so the error-handling surface is
  /// uniform.
  factory EncryptedMedicationGroupPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedMedicationGroupPayload JSON is missing integer "v"',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedMedicationGroupPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedMedicationGroupPayload JSON "v"=$rawVersion is newer '
        'than this build supports (v$currentSchemaVersion). Upgrade the '
        'app.',
      );
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException(
        'EncryptedMedicationGroupPayload JSON is missing "name"',
      );
    }

    // Member list tolerates empty lists (a freshly-created group before
    // the user picks members) and drops non-string entries rather than
    // failing the whole row.
    final membersRaw = json['members'];
    final members = <String>[];
    if (membersRaw is List) {
      for (final m in membersRaw) {
        if (m is String && m.isNotEmpty) members.add(m);
      }
    }

    return EncryptedMedicationGroupPayload(
      schemaVersion: rawVersion,
      name: name,
      schedule: MedicationSchedule.fromWireJson(json['schedule']),
      memberMedicationIds: List.unmodifiable(members),
    );
  }

  /// The schema version written by this build.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String name;
  final MedicationSchedule schedule;
  final List<String> memberMedicationIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        // Omit `schedule` for the `asNeeded` default — same approach as
        // the medication payload, keeps diffs small when sync lands.
        if (schedule.kind != ScheduleKind.asNeeded)
          'schedule': schedule.toWireJson(),
        // Member list is always emitted (even empty) so decoders can
        // distinguish "no members, intentionally" from "field absent,
        // read as default".
        'members': List<String>.from(memberMedicationIds),
      };
}
