import 'package:freezed_annotation/freezed_annotation.dart';

part 'observation.freezed.dart';

/// High-level bucket for a timeline note. Persisted as an index —
/// append only; unknown indices decode to [other].
enum ObservationCategory {
  general,
  wellbeing,
  sensory,
  regulation,
  school,
  health,
  other,
}

/// One dated note on a Person's timeline.
@freezed
abstract class Observation with _$Observation {
  const factory Observation({
    required String id,
    required String personId,
    required DateTime observedAt,
    required ObservationCategory category,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? profileEntryId,
    String? notes,
    @Default(<String>[]) List<String> tags,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Observation;
}

/// Short UI label for the observation category enum.
String labelForObservationCategory(ObservationCategory c) {
  switch (c) {
    case ObservationCategory.general:
      return 'General';
    case ObservationCategory.wellbeing:
      return 'Wellbeing';
    case ObservationCategory.sensory:
      return 'Sensory';
    case ObservationCategory.regulation:
      return 'Regulation';
    case ObservationCategory.school:
      return 'School';
    case ObservationCategory.health:
      return 'Health';
    case ObservationCategory.other:
      return 'Other';
  }
}
