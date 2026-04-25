import 'package:freezed_annotation/freezed_annotation.dart';

part 'program.freezed.dart';

/// High-level bucket for a program row — kept small like milestone kinds.
enum ProgramKind {
  school,
  camp,
  afterCare,
  other,
}

String labelForProgramKind(ProgramKind k) {
  switch (k) {
    case ProgramKind.school:
      return 'School';
    case ProgramKind.camp:
      return 'Camp';
    case ProgramKind.afterCare:
      return 'After-care';
    case ProgramKind.other:
      return 'Other';
  }
}

@freezed
abstract class Program with _$Program {
  const factory Program({
    required String id,
    required String personId,
    required ProgramKind kind,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? phone,
    String? contactName,
    String? contactRole,
    String? email,
    String? address,
    String? websiteUrl,
    String? hours,
    String? notes,
    String? providerId,
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Program;
}
