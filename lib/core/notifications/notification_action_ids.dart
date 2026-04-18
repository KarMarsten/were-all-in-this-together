/// Stable identifier strings for notification action buttons.
///
/// These must match:
///
/// * The id we pass to `DarwinNotificationAction.plain(...)` in
///   `LocalNotificationService.initialize`.
/// * The id we compare against in the background handler to decide
///   whether the user tapped Taken, Skip, or the notification body.
/// * The id the iOS AppDelegate registers with
///   `UNUserNotificationCenter` so the category exists before the
///   app first schedules a reminder.
///
/// Centralising them makes a rename a single-file change instead of
/// a cross-isolate scavenger hunt.
abstract final class NotificationActionIds {
  /// User confirmed they took the dose. Writes a `taken` dose log
  /// and cancels all remaining nags for this dose instance.
  static const String taken = 'TAKEN';

  /// User deliberately skipped the dose (e.g. took it early,
  /// doctor said not today). Writes a `skipped` dose log and
  /// cancels remaining nags.
  static const String skip = 'SKIP';
}
