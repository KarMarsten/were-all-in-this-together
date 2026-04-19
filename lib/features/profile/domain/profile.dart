import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// One Person's profile row — the encrypted living-document baselines
/// that future `ProfileEntry` / observation features will extend.
///
/// Immutable; all writes go through `ProfileRepository`.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String personId,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? communicationNotes,
    String? sleepBaseline,
    String? appetiteBaseline,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Profile;
}
