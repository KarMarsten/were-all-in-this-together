import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_site.freezed.dart';

@freezed
abstract class AppSite with _$AppSite {
  const factory AppSite({
    required String id,
    required String personId,
    required String title,
    required String url,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? notes,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _AppSite;
}
