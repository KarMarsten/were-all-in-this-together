import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';
import 'package:were_all_in_this_together/features/safety_plan/ui/calm_screen.dart';

import '../../helpers/recording_url_opener.dart';

Person _testPerson() {
  final t = DateTime.utc(2026, 1, 15);
  return Person(
    id: 'person-1',
    displayName: 'Riley',
    createdAt: t,
    updatedAt: t,
  );
}

Profile _testProfile({String? communication}) {
  final t = DateTime.utc(2026, 1, 15);
  return Profile(
    id: 'profile-1',
    personId: 'person-1',
    createdAt: t,
    updatedAt: t,
    communicationNotes: communication,
  );
}

ProfileEntry _line({
  required String id,
  required ProfileEntrySection section,
  required String label,
}) {
  final t = DateTime.utc(2026, 1, 15);
  return ProfileEntry(
    id: id,
    profileId: 'profile-1',
    personId: 'person-1',
    section: section,
    status: ProfileEntryStatus.active,
    label: label,
    createdAt: t,
    updatedAt: t,
  );
}

ProfileEntry _otherLine() {
  return _line(
    id: 'entry-other',
    section: ProfileEntrySection.other,
    label: 'Misc',
  );
}

Widget _pumpCalm({required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      urlOpenerProvider.overrideWith((_) => RecordingUrlOpener()),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/calm',
        routes: [
          GoRoute(
            path: '/calm',
            builder: (context, state) => const CalmScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Calm shows What helps card for active line', (tester) async {
    await tester.pumpWidget(
      _pumpCalm(
        overrides: [
          activePersonProvider.overrideWith((ref) async => _testPerson()),
          activePersonProfileProvider.overrideWith(
            (ref) async => _testProfile(),
          ),
          activeProfileLinesProvider.overrideWith(
            (ref) async => [
              _line(
                id: 'entry-helps',
                section: ProfileEntrySection.whatHelps,
                label: 'Soft blanket',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WHAT HELPS'), findsOneWidget);
    expect(find.text('Soft blanket'), findsOneWidget);
    expect(find.textContaining('Riley'), findsWidgets);
  });

  testWidgets('Calm shows Triggers card for active line', (tester) async {
    await tester.pumpWidget(
      _pumpCalm(
        overrides: [
          activePersonProvider.overrideWith((ref) async => _testPerson()),
          activePersonProfileProvider.overrideWith(
            (ref) async => _testProfile(),
          ),
          activeProfileLinesProvider.overrideWith(
            (ref) async => [
              _line(
                id: 'entry-trigger',
                section: ProfileEntrySection.trigger,
                label: 'Crowded stores',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRIGGERS'), findsOneWidget);
    expect(find.text('Crowded stores'), findsOneWidget);
  });

  testWidgets(
    'Calm shows profile empty-state when only non-Calm sections exist',
    (tester) async {
      await tester.pumpWidget(
        _pumpCalm(
          overrides: [
            activePersonProvider.overrideWith((ref) async => _testPerson()),
            activePersonProfileProvider.overrideWith(
              (ref) async => _testProfile(),
            ),
            activeProfileLinesProvider.overrideWith(
              (ref) async => [_otherLine()],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FROM PROFILE'), findsOneWidget);
      expect(find.text('WHAT HELPS'), findsNothing);
    },
  );

  testWidgets('Calm shows baselines when filled', (tester) async {
    await tester.pumpWidget(
      _pumpCalm(
        overrides: [
          activePersonProvider.overrideWith((ref) async => _testPerson()),
          activePersonProfileProvider.overrideWith(
            (ref) async => _testProfile(communication: 'AAC board'),
          ),
          activeProfileLinesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BASELINES'), findsOneWidget);
    expect(find.textContaining('AAC board'), findsOneWidget);
  });
}
