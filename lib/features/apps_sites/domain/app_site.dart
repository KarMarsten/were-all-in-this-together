import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_site.freezed.dart';

enum AppSiteCategory {
  portal,
  school,
  therapy,
  insurance,
  app,
  other,
}

String labelForAppSiteCategory(AppSiteCategory category) {
  switch (category) {
    case AppSiteCategory.portal:
      return 'Portal';
    case AppSiteCategory.school:
      return 'School';
    case AppSiteCategory.therapy:
      return 'Therapy';
    case AppSiteCategory.insurance:
      return 'Insurance';
    case AppSiteCategory.app:
      return 'App';
    case AppSiteCategory.other:
      return 'Other';
  }
}

@freezed
abstract class AppSite with _$AppSite {
  const factory AppSite({
    required String id,
    required String personId,
    required String title,
    required String url,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(AppSiteCategory.portal) AppSiteCategory category,
    String? usernameHint,
    String? loginNote,
    String? notes,
    String? providerId,
    String? programId,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _AppSite;
}
