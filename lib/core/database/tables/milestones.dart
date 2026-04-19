import 'package:drift/drift.dart';

/// Milestones table — one row per dated event in a Person's life
/// history that doesn't fit the medication / appointment / provider
/// schema. Diagnoses, shots, developmental firsts, moves, surgeries.
///
/// Milestones are retrospective: they record "this happened then",
/// not "this will happen". There is no schedule and no reminder.
/// The question this domain exists to answer is "when did X get
/// their last flu shot?" / "when were they diagnosed?" / "when did
/// they start walking?".
///
/// Storage:
///
/// * `occurredAt` — UTC epoch ms. For non-`exact` precision this is
///   the *start* of the period (e.g. 2019-01-01 UTC for "sometime
///   in 2019"). Plaintext on the row so lists can sort and filter
///   without decrypting every payload, same rationale as
///   `appointments.scheduledAt`.
/// * `precision` — small enum index controlling how the UI renders
///   the date and how user-facing search should interpret fuzzy
///   queries. Plaintext so range queries can honour precision
///   without a decrypt pass (a milestone with year precision should
///   match a year-wide window, not just the stored epoch ms).
/// * `kind` — small enum index controlling the row's icon / colour
///   / grouping on the list screen. Plaintext for the same reason:
///   grouping and filtering shouldn't require decrypting every row.
/// * `providerId` — optional soft reference to a `CareProvider`
///   row. Not a declared SQL foreign key (mirrors every other
///   cross-domain reference in this app — Phase 2 sync needs to
///   tolerate arrival order).
/// * `payload` — envelope-encrypted blob under the owning Person's
///   key holding title and notes.
///
/// The plaintext leak surface is "the user has *some* milestone
/// in 2019" — not *what* kind of milestone it is (the `kind`
/// column leaks the category, which is a deliberate trade-off:
/// grouping the list screen without it requires decrypting every
/// row on every open, which hurts startup more than the category
/// label leaks).
///
/// Introduced in schema v8; see `AppDatabase.migration`.
@DataClassName('MilestoneRow')
class Milestones extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person's id. Not a declared SQL foreign key — Phase 2
  /// sync needs to tolerate arrival order.
  TextColumn get personId => text()();

  /// Epoch milliseconds (UTC). Start-of-period when `precision` is
  /// coarser than `exact`.
  IntColumn get occurredAt => integer()();

  /// `MilestonePrecision.index`: 0=year, 1=month, 2=day, 3=exact.
  /// Kept as an int so adding a new precision tier is backward
  /// compatible — newer indices simply render as the closest
  /// older tier until the app is upgraded.
  IntColumn get precision => integer()();

  /// `MilestoneKind.index`: small enum with diagnosis / vaccine /
  /// development / health / life / other. Same forward-compat
  /// rule as `precision`.
  IntColumn get kind => integer()();

  /// Optional link to `CareProvider.id`. Archived providers are
  /// still valid targets — "Diagnosed by Dr. Chen" should keep
  /// attribution after Dr. Chen is retired from the active list.
  TextColumn get providerId => text().nullable()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not archived.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every
  /// write.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Identifier of the device that last wrote this row. `null` in
  /// Phase 1 (single device); populated in Phase 2.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Which key generation decrypted this row's payload.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
