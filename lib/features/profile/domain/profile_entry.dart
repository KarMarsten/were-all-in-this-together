import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entry.freezed.dart';

/// High-level bucket for a structured profile line item. Order is the
/// persisted index — append only; unknown indices decode to [other].
enum ProfileEntrySection {
  stim,
  preferenceSensory,
  preferenceFood,
  preferenceClothing,
  preferenceSocial,
  routineBlock,
  routineStep,
  trigger,
  whatHelps,
  earlySign,
  other,
}

/// Whether the entry is currently relevant to day-to-day care.
enum ProfileEntryStatus {
  active,
  paused,
  resolved,
}

/// One structured line under a Person's profile row.
@freezed
abstract class ProfileEntry with _$ProfileEntry {
  const factory ProfileEntry({
    required String id,
    required String profileId,
    required String personId,
    required ProfileEntrySection section,
    required ProfileEntryStatus status,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentEntryId,
    DateTime? firstNoted,
    DateTime? lastNoted,
    String? details,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _ProfileEntry;
}

/// Human label for [ProfileEntrySection] (list + form).
String labelForProfileEntrySection(ProfileEntrySection s) {
  switch (s) {
    case ProfileEntrySection.stim:
      return 'Stim';
    case ProfileEntrySection.preferenceSensory:
      return 'Sensory preference';
    case ProfileEntrySection.preferenceFood:
      return 'Food & eating';
    case ProfileEntrySection.preferenceClothing:
      return 'Clothing';
    case ProfileEntrySection.preferenceSocial:
      return 'Social';
    case ProfileEntrySection.routineBlock:
      return 'Routine block';
    case ProfileEntrySection.routineStep:
      return 'Routine step';
    case ProfileEntrySection.trigger:
      return 'Trigger';
    case ProfileEntrySection.whatHelps:
      return 'What helps';
    case ProfileEntrySection.earlySign:
      return 'Early sign';
    case ProfileEntrySection.other:
      return 'Other';
  }
}

/// Human label for [ProfileEntryStatus].
String labelForProfileEntryStatus(ProfileEntryStatus s) {
  switch (s) {
    case ProfileEntryStatus.active:
      return 'Active';
    case ProfileEntryStatus.paused:
      return 'Paused';
    case ProfileEntryStatus.resolved:
      return 'Resolved';
  }
}
