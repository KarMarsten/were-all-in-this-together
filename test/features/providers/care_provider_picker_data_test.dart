import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/providers.dart';

/// [CareProviderPickerData.byId] is the helper the medication list tile
/// uses to resolve a stored `prescriberId` back to a human-readable
/// name. The contract the rest of the app relies on:
///
/// * Active *and* archived providers must be findable — archived
///   entries stay in the picker so history doesn't lose its link.
/// * Missing ids return null cleanly rather than throwing, so a tile
///   whose link points at a forgotten / not-yet-synced row can fall
///   back to the free-text prescriber.
void main() {
  final now = DateTime.utc(2030);
  final active = CareProvider(
    id: 'p1',
    personId: 'alex',
    name: 'Dr. Chen',
    kind: CareProviderKind.specialist,
    createdAt: now,
    updatedAt: now,
  );
  final archived = CareProvider(
    id: 'p2',
    personId: 'alex',
    name: 'Dr. Ortiz',
    kind: CareProviderKind.specialist,
    createdAt: now,
    updatedAt: now,
    deletedAt: now,
  );

  test('finds providers in either the active or the archived list', () {
    final data = CareProviderPickerData(
      active: [active],
      archived: [archived],
    );

    expect(data.byId('p1')?.name, 'Dr. Chen');
    expect(data.byId('p2')?.name, 'Dr. Ortiz');
    expect(data.byId('p2')?.deletedAt, isNotNull);
  });

  test('returns null for unknown ids rather than throwing', () {
    const empty = CareProviderPickerData(active: [], archived: []);
    expect(empty.byId('missing'), isNull);
  });
}
