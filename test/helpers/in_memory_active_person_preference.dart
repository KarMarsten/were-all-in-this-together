import 'package:were_all_in_this_together/features/people/data/active_person_preference.dart';

/// In-memory test double for [ActivePersonPreference].
class InMemoryActivePersonPreference implements ActivePersonPreference {
  InMemoryActivePersonPreference({String? initialId}) : _id = initialId;

  String? _id;

  @override
  Future<String?> getActivePersonId() async => _id;

  @override
  Future<void> setActivePersonId(String? id) async {
    _id = id;
  }
}
