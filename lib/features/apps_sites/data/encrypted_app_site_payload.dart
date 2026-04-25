/// JSON inside the app_sites table `payload` column before encryption.
class EncryptedAppSitePayload {
  const EncryptedAppSitePayload({
    required this.schemaVersion,
    required this.title,
    required this.url,
    this.categoryIndex,
    this.usernameHint,
    this.loginNote,
    this.notes,
    this.providerId,
    this.programId,
  });

  factory EncryptedAppSitePayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedAppSitePayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedAppSitePayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedAppSitePayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final title = json['title'];
    final url = json['url'];
    if (title is! String || url is! String) {
      throw const FormatException(
        'EncryptedAppSitePayload JSON is missing "title" or "url"',
      );
    }
    return EncryptedAppSitePayload(
      schemaVersion: rawVersion,
      title: title,
      url: url,
      categoryIndex: json['category'] as int?,
      usernameHint: json['usernameHint'] as String?,
      loginNote: json['loginNote'] as String?,
      notes: json['notes'] as String?,
      providerId: json['providerId'] as String?,
      programId: json['programId'] as String?,
    );
  }

  static const int currentSchemaVersion = 3;

  final int schemaVersion;
  final String title;
  final String url;
  final int? categoryIndex;
  final String? usernameHint;
  final String? loginNote;
  final String? notes;
  final String? providerId;
  final String? programId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'title': title,
        'url': url,
        if (categoryIndex != null) 'category': categoryIndex,
        if (usernameHint != null) 'usernameHint': usernameHint,
        if (loginNote != null) 'loginNote': loginNote,
        if (notes != null) 'notes': notes,
        if (providerId != null) 'providerId': providerId,
        if (programId != null) 'programId': programId,
      };
}
