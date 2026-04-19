import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry_contract.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

ProfileEntry _entry({
  required String id,
  ProfileEntrySection section = ProfileEntrySection.stim,
  ProfileEntryStatus status = ProfileEntryStatus.active,
  String label = 'x',
}) {
  final t = DateTime.utc(2026);
  return ProfileEntry(
    id: id,
    profileId: 'p',
    personId: 'person',
    section: section,
    status: status,
    label: label,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('guidanceForProfileEntrySection', () {
    test('every section has non-empty guidance', () {
      for (final s in ProfileEntrySection.values) {
        expect(guidanceForProfileEntrySection(s), isNotEmpty);
      }
    });
  });

  group('detailsStronglyRecommended', () {
    test('true for trigger, whatHelps, earlySign, routineStep', () {
      expect(detailsStronglyRecommended(ProfileEntrySection.trigger), isTrue);
      expect(detailsStronglyRecommended(ProfileEntrySection.whatHelps), isTrue);
      expect(detailsStronglyRecommended(ProfileEntrySection.earlySign), isTrue);
      expect(
        detailsStronglyRecommended(ProfileEntrySection.routineStep),
        isTrue,
      );
    });

    test('false for remaining sections', () {
      const weak = <ProfileEntrySection>{
        ProfileEntrySection.stim,
        ProfileEntrySection.preferenceSensory,
        ProfileEntrySection.preferenceFood,
        ProfileEntrySection.preferenceClothing,
        ProfileEntrySection.preferenceSocial,
        ProfileEntrySection.routineBlock,
        ProfileEntrySection.other,
      };
      for (final s in weak) {
        expect(detailsStronglyRecommended(s), isFalse);
      }
    });
  });

  group('detailsFieldLabelForSection', () {
    test('recommended vs optional label', () {
      expect(
        detailsFieldLabelForSection(ProfileEntrySection.trigger),
        'Details (recommended)',
      );
      expect(
        detailsFieldLabelForSection(ProfileEntrySection.stim),
        'Details (optional)',
      );
    });
  });

  group('detailsFieldHelperForSection', () {
    test('null when details optional', () {
      expect(detailsFieldHelperForSection(ProfileEntrySection.stim), isNull);
    });

    test('non-null when details recommended', () {
      expect(
        detailsFieldHelperForSection(ProfileEntrySection.whatHelps),
        isNotNull,
      );
    });

    test('stable helper copy for recommended sections', () {
      const expected =
          'Extra context makes this easier for another caregiver to use '
          'without guessing.';
      expect(
        detailsFieldHelperForSection(ProfileEntrySection.earlySign),
        expected,
      );
    });
  });

  group('sectionSurfacesOnCalm', () {
    test('other is excluded', () {
      expect(sectionSurfacesOnCalm(ProfileEntrySection.other), isFalse);
    });

    test('all other sections included', () {
      for (final s in ProfileEntrySection.values) {
        if (s == ProfileEntrySection.other) continue;
        expect(sectionSurfacesOnCalm(s), isTrue);
      }
    });
  });

  group('calmPreferenceSections', () {
    test('stable section order for merged Calm card', () {
      expect(
        calmPreferenceSections.first,
        ProfileEntrySection.preferenceSensory,
      );
      expect(
        calmPreferenceSections.last,
        ProfileEntrySection.preferenceSocial,
      );
    });

    test('covers the four preference buckets', () {
      expect(calmPreferenceSections, hasLength(4));
      expect(
        calmPreferenceSection(ProfileEntrySection.preferenceSensory),
        isTrue,
      );
      expect(
        calmPreferenceSection(ProfileEntrySection.preferenceFood),
        isTrue,
      );
      expect(
        calmPreferenceSection(ProfileEntrySection.preferenceClothing),
        isTrue,
      );
      expect(
        calmPreferenceSection(ProfileEntrySection.preferenceSocial),
        isTrue,
      );
      expect(calmPreferenceSection(ProfileEntrySection.trigger), isFalse);
    });
  });

  group('calmHasStructuredProfileContent', () {
    test('false for empty', () {
      expect(calmHasStructuredProfileContent(const []), isFalse);
    });

    test('false when only other section', () {
      expect(
        calmHasStructuredProfileContent([
          _entry(id: '1', section: ProfileEntrySection.other),
        ]),
        isFalse,
      );
    });

    test('true for active stim row', () {
      expect(
        calmHasStructuredProfileContent([_entry(id: '1')]),
        isTrue,
      );
    });

    test('true for early sign section', () {
      expect(
        calmHasStructuredProfileContent([
          _entry(id: '2', section: ProfileEntrySection.earlySign),
        ]),
        isTrue,
      );
    });
  });

  group('activeProfileLinesProvider', () {
    test('filters to active status only', () async {
      final container = ProviderContainer(
        overrides: [
          profileEntriesForActivePersonProvider.overrideWith((ref) async {
            return [
              _entry(id: 'a'),
              _entry(id: 'b', status: ProfileEntryStatus.paused),
              _entry(id: 'c', status: ProfileEntryStatus.resolved),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);

      final lines = await container.read(activeProfileLinesProvider.future);
      expect(lines, hasLength(1));
      expect(lines.single.id, 'a');
    });
  });
}
