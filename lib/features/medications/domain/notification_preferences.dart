import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// Per-device, non-PII preferences for how medication reminder
/// nagging behaves.
///
/// Two knobs:
///
/// * [nagIntervalMinutes] — how long after an unacknowledged
///   reminder we fire a follow-up. "Acknowledged" means the user
///   has tapped Taken or Skip on the notification itself, or has
///   logged the dose in the Today screen.
/// * [nagCap] — maximum number of follow-ups after the initial
///   reminder. `cap=0` disables nagging entirely: a single reminder
///   fires and that's it.
///
/// These are **defaults**. A medication can override either of them
/// when its adherence really matters (e.g. time-sensitive insulin)
/// or really doesn't (e.g. an as-needed rescue inhaler).
///
/// Stored unencrypted on the device because these are preferences,
/// not PII — they don't reveal anything about the Person's health
/// that the OS doesn't already see from the scheduled notifications
/// themselves.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  // `@Default` is resolved at codegen time so the annotation's argument
  // has to be a top-level constant expression — static class fields
  // don't qualify. We therefore inline the magic numbers here and rely
  // on the `default*` constants below as the source of truth that tests
  // and UI code should reference.
  const factory NotificationPreferences({
    @Default(10) int nagIntervalMinutes,
    @Default(3) int nagCap,
  }) = _NotificationPreferences;

  /// Sensible out-of-the-box interval. Long enough that a caregiver
  /// can walk to the kitchen and pour water without being nagged,
  /// short enough that a genuinely missed dose is caught while the
  /// window still matters.
  static const int defaultNagIntervalMinutes = 10;

  /// Sensible out-of-the-box cap. Three follow-ups at 10-minute
  /// spacing covers a 30-minute window after the original alarm —
  /// enough to rescue a distracted morning without degenerating
  /// into a full-day ping storm.
  static const int defaultNagCap = 3;

  /// Lowest interval we accept. Sub-minute nags turn the OS into a
  /// siren; values that low are almost certainly a UI bug or a
  /// typo. Minute granularity also matches what the settings UI
  /// can express with a minute picker.
  static const int minNagIntervalMinutes = 1;

  /// Upper bound on interval. 240 minutes = 4 hours. Beyond that
  /// the "reminder" is really a new scheduled dose and belongs in
  /// the schedule editor, not the nag config.
  static const int maxNagIntervalMinutes = 240;

  /// Upper bound on how many follow-ups we'll ever schedule.
  /// Keeps us comfortably inside iOS's 64-pending-notifications
  /// per-app ceiling when combined with the rolling-window
  /// reconciler.
  static const int maxNagCap = 10;
}
