import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/reports/data/care_summary_pdf.dart';

void main() {
  test('buildCareSummaryPdf returns non-empty PDF bytes', () async {
    final t = DateTime.utc(2026);
    final profile = Profile(
      id: 'p1',
      personId: 'per1',
      communicationNotes: 'AAC preferred',
      createdAt: t,
      updatedAt: t,
    );
    final entry = ProfileEntry(
      id: 'e1',
      profileId: 'p1',
      personId: 'per1',
      section: ProfileEntrySection.whatHelps,
      status: ProfileEntryStatus.active,
      label: 'Weighted blanket',
      details: 'Ten minutes in quiet room',
      createdAt: t,
      updatedAt: t,
    );

    final bytes = await buildCareSummaryPdf(
      personName: 'Test child',
      activeEntries: [entry],
      profile: profile,
      generatedAt: t,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
