import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/widgets/person_avatar.dart';

void main() {
  group('PersonAvatar.initialsFor', () {
    test('returns the first letter of a single-word name, uppercased', () {
      expect(PersonAvatar.initialsFor('alex'), 'A');
    });

    test('returns first + last initial for multi-word names', () {
      expect(PersonAvatar.initialsFor('Sam Jones'), 'SJ');
      expect(PersonAvatar.initialsFor('Mary Elizabeth Jones'), 'MJ');
    });

    test('trims whitespace and collapses multiple spaces', () {
      expect(PersonAvatar.initialsFor('  Alex   Jones  '), 'AJ');
    });

    test('handles an empty name with a safe fallback glyph', () {
      expect(PersonAvatar.initialsFor('   '), '?');
      expect(PersonAvatar.initialsFor(''), '?');
    });

    test('uses grapheme cluster (not UTF-16 code unit) for first letter', () {
      // 'A' + combining acute — stays as a single grapheme cluster rather
      // than splitting on the code unit boundary and dropping the accent.
      // We don't attempt NFC normalisation; the initial comes back in the
      // same form it was entered.
      expect(PersonAvatar.initialsFor('A\u0301lex'), 'A\u0301');
    });
  });

  testWidgets('renders the computed initials and a semantic label',
      (tester) async {
    final person = Person(
      id: 'person-deterministic-id',
      displayName: 'Sam Jones',
      createdAt: DateTime.utc(2030),
      updatedAt: DateTime.utc(2030),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: PersonAvatar(person: person))),
      ),
    );

    expect(find.text('SJ'), findsOneWidget);
    expect(find.bySemanticsLabel('Sam Jones, avatar'), findsOneWidget);
  });
}
