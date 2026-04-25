import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/programs/data/program_repository.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late ProgramRepository programs;
  late String personId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    people = PersonRepository(
      database: db,
      crypto: crypto,
      keys: keys,
    );
    programs = ProgramRepository(
      database: db,
      crypto: crypto,
      keys: keys,
    );
    final p = await people.create(displayName: 'Alex');
    personId = p.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('create list round-trip', () async {
    final created = await programs.create(
      personId: personId,
      kind: ProgramKind.school,
      name: 'Roosevelt Elementary',
      phone: '555-0100',
      notes: 'Main office',
      providerId: 'provider-1',
    );
    final list = await programs.listActiveForPerson(personId);
    expect(list, hasLength(1));
    expect(list.single.name, 'Roosevelt Elementary');
    expect(list.single.kind, ProgramKind.school);
    final again = await programs.findById(created.id);
    expect(again?.phone, '555-0100');
    expect(again?.providerId, 'provider-1');
  });
}
