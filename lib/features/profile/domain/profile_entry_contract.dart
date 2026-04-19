import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';

// ---------------------------------------------------------------------------
// Profile entry framework — section contracts (guidance + where data shows).
//
// * Label: always required (short handle for lists and Calm).
// * Details: optional unless [detailsStronglyRecommended]; still never blocked
//   on save — hints steer quality.
// * Status: [ProfileEntryStatus.active] rows surface on Calm and in the
//   default Profile list; paused/resolved stay editable and appear when
//   “All statuses” is selected on Profile.
// * Notes: any non-archived line can be linked from a Note; pickers prefer
//   active lines only.
// ---------------------------------------------------------------------------

/// Shown under the section picker on the entry form.
String guidanceForProfileEntrySection(ProfileEntrySection section) {
  switch (section) {
    case ProfileEntrySection.stim:
      return 'Regulating or joy-seeking movement or sound — what it looks '
          'like and when it tends to show up.';
    case ProfileEntrySection.preferenceSensory:
      return 'What sensory input helps vs overwhelms (light, sound, touch, '
          'smell, movement).';
    case ProfileEntrySection.preferenceFood:
      return 'Safe foods, textures to avoid, mealtime supports.';
    case ProfileEntrySection.preferenceClothing:
      return 'Fabric, fit, tags, shoes — what works day-to-day.';
    case ProfileEntrySection.preferenceSocial:
      return 'Social pacing: 1:1 vs groups, warm-up time, how to decline '
          'gracefully.';
    case ProfileEntrySection.routineBlock:
      return 'Named part of the day (morning, school, bedtime). Add steps '
          'as separate entries under this block.';
    case ProfileEntrySection.routineStep:
      return 'One concrete step under a routine block — order is implied by '
          'how you phrase the label.';
    case ProfileEntrySection.trigger:
      return 'What tends to precede overload or meltdown — include intensity '
          'or context in details when you can.';
    case ProfileEntrySection.whatHelps:
      return 'Concrete supports that land in the moment — who does what, '
          'what to say, what to bring.';
    case ProfileEntrySection.earlySign:
      return 'Early, gentler signals before things escalate — easy to scan '
          'when you are depleted.';
    case ProfileEntrySection.other:
      return 'Anything that does not fit the other buckets yet still belongs '
          'in the structured list.';
  }
}

bool detailsStronglyRecommended(ProfileEntrySection section) {
  switch (section) {
    case ProfileEntrySection.trigger:
    case ProfileEntrySection.whatHelps:
    case ProfileEntrySection.earlySign:
    case ProfileEntrySection.routineStep:
      return true;
    case ProfileEntrySection.stim:
    case ProfileEntrySection.preferenceSensory:
    case ProfileEntrySection.preferenceFood:
    case ProfileEntrySection.preferenceClothing:
    case ProfileEntrySection.preferenceSocial:
    case ProfileEntrySection.routineBlock:
    case ProfileEntrySection.other:
      return false;
  }
}

String detailsFieldLabelForSection(ProfileEntrySection section) {
  return detailsStronglyRecommended(section)
      ? 'Details (recommended)'
      : 'Details (optional)';
}

String? detailsFieldHelperForSection(ProfileEntrySection section) {
  if (!detailsStronglyRecommended(section)) return null;
  return 'Extra context makes this easier for another caregiver to use '
      'without guessing.';
}

/// Sections whose active rows may appear on Calm (see calm layout).
bool sectionSurfacesOnCalm(ProfileEntrySection section) {
  return switch (section) {
    ProfileEntrySection.other => false,
    _ => true,
  };
}

/// Preference-type sections merged into one Calm card.
const List<ProfileEntrySection> calmPreferenceSections = [
  ProfileEntrySection.preferenceSensory,
  ProfileEntrySection.preferenceFood,
  ProfileEntrySection.preferenceClothing,
  ProfileEntrySection.preferenceSocial,
];

bool calmPreferenceSection(ProfileEntrySection section) {
  return calmPreferenceSections.contains(section);
}

/// True when [entries] already contains only active rows and at least one
/// should render in the Calm structured stack (excluding baselines).
/// Expects [entries] to already be limited to rows you show on Calm
/// (typically [ProfileEntryStatus.active] only).
bool calmHasStructuredProfileContent(List<ProfileEntry> entries) {
  return entries.any((e) => sectionSurfacesOnCalm(e.section));
}
