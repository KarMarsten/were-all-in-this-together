import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/apps_sites/data/app_site_repository.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late AppSiteRepository sites;
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
    sites = AppSiteRepository(
      database: db,
      crypto: crypto,
      keys: keys,
    );
    final p = await people.create(displayName: 'Jamie');
    personId = p.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('create normalizes URL and round-trips', () async {
    await sites.create(
      personId: personId,
      title: 'District portal',
      url: 'example.org/parents',
      notes: 'Use SSO',
    );
    final list = await sites.listActiveForPerson(personId);
    expect(list, hasLength(1));
    expect(list.single.title, 'District portal');
    expect(list.single.url, 'https://example.org/parents');
  });
}
