import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';

/// Stable placeholder for the "ACK'd by" column while the app is
/// single-caregiver. Phase 2 replaces this with whatever auth profile
/// the backend attaches to the incoming write.
const String kThisDeviceAckLabel = 'This device';

/// Label used when a medication referenced by a dose log no longer
/// resolves (e.g. the row was hard-deleted, or the Person key was
/// wiped). Keeps the report honest instead of silently omitting a
/// real dose.
const String kUnknownMedicationLabel = 'Unknown medication';

/// Same, for a missing Person.
const String kUnknownPersonLabel = 'Unknown person';

/// Read-only aggregator over `DoseLogRepository`, `PersonRepository`
/// and `MedicationRepository`.
///
/// Responsible for:
///
/// * Resolving every Person whose doses fall in the query window
///   (scoped to one Person if the query names one).
/// * Resolving the medications they own — both active and archived,
///   because a report spanning the last 30 days can legitimately
///   cover meds that were archived mid-window.
/// * Joining dose logs against those medications and producing a
///   flat [AdherenceReportRow] stream sorted newest-scheduled first.
class AdherenceReportService {
  AdherenceReportService({
    required PersonRepository people,
    required MedicationRepository medications,
    required DoseLogRepository doseLogs,
  })  : _people = people,
        _medications = medications,
        _doseLogs = doseLogs;

  final PersonRepository _people;
  final MedicationRepository _medications;
  final DoseLogRepository _doseLogs;

  /// Fetch every [AdherenceReportRow] matching [query], sorted by
  /// `scheduledAt` descending (most recent first) — which is what
  /// the UI and the PDF want to show at the top.
  Future<List<AdherenceReportRow>> fetch(AdherenceReportQuery query) async {
    final people = await _resolvePeople(query.personId);
    if (people.isEmpty) return const <AdherenceReportRow>[];

    // Build a single flat medication list across all in-scope people.
    // We fetch archived rows too so that a dose taken two weeks ago on
    // a med that was archived last Friday still renders with its
    // proper name rather than "Unknown medication".
    final medsById = <String, Medication>{};
    final personNameById = <String, String>{};
    for (final person in people) {
      personNameById[person.id] = person.displayName;
      final active = await _medications.listActiveForPerson(person.id);
      final archived = await _medications.listArchivedForPerson(person.id);
      for (final m in [...active, ...archived]) {
        medsById[m.id] = m;
      }
    }

    if (medsById.isEmpty) return const <AdherenceReportRow>[];

    final logs = await _doseLogs.forMedicationsInRange(
      medicationIds: medsById.keys,
      fromInclusive: query.fromInclusive,
      toExclusive: query.toExclusive,
    );

    final rows = <AdherenceReportRow>[];
    for (final log in logs) {
      final med = medsById[log.medicationId];
      final personName = personNameById[log.personId];
      rows.add(
        AdherenceReportRow(
          scheduledAt: log.scheduledAt.toUtc(),
          loggedAt: log.loggedAt.toUtc(),
          personId: log.personId,
          personName: personName ?? kUnknownPersonLabel,
          medicationId: log.medicationId,
          medicationName: med?.name ?? kUnknownMedicationLabel,
          outcome: log.outcome,
          // Phase-1 placeholder; lastWriterDeviceId is meant to be a
          // UUID, not a caregiver label, so we don't surface it as-is.
          ackedBy: kThisDeviceAckLabel,
        ),
      );
    }

    // Newest dose first, ties broken by loggedAt (also desc) so rapid
    // successive ACKs stay deterministic across runs.
    rows.sort((a, b) {
      final byScheduled = b.scheduledAt.compareTo(a.scheduledAt);
      if (byScheduled != 0) return byScheduled;
      return b.loggedAt.compareTo(a.loggedAt);
    });

    return rows;
  }

  Future<List<Person>> _resolvePeople(String? personId) async {
    final all = await _people.listActive();
    if (personId == null) return all;
    return [for (final p in all) if (p.id == personId) p];
  }
}

/// App-wide [AdherenceReportService]. Tests override with an in-memory
/// variant that ignores encryption.
final adherenceReportServiceProvider = Provider<AdherenceReportService>((ref) {
  return AdherenceReportService(
    people: ref.watch(personRepositoryProvider),
    medications: ref.watch(medicationRepositoryProvider),
    doseLogs: ref.watch(doseLogRepositoryProvider),
  );
});

/// The report that corresponds to a given query. Invalidate when
/// the underlying dose logs change (e.g. after a drainer pass).
// ignore: specify_nonobvious_property_types
final adherenceReportProvider =
    FutureProvider.family<List<AdherenceReportRow>, AdherenceReportQuery>(
        (ref, query) async {
  final svc = ref.watch(adherenceReportServiceProvider);
  return svc.fetch(query);
});
