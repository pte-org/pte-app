import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import '../../domain/entities/host_exam_summary.dart';

class HostExamSummaryModel extends HostExamSummary {
  const HostExamSummaryModel({
    required super.publicId,
    required super.sessionCode,
    required super.name,
    required super.status,
    required super.examVersionPublicId,
  });

  factory HostExamSummaryModel.fromJson(Map<String, dynamic> json) {
    return HostExamSummaryModel(
      publicId: _requiredString(json['publicId'], 'publicId'),
      sessionCode: _nullableString(json['sessionCode']),
      name: _nullableString(json['name']) ?? ExamPreviewStrings.untitledExam,
      status: (_nullableString(json['status']) ?? 'UNKNOWN').toUpperCase(),
      examVersionPublicId: _nullableString(json['examVersionPublicId']),
    );
  }
}

String _requiredString(Object? value, String field) {
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    throw FormatException(ExamPreviewStrings.missingField(field));
  }
  return normalized;
}

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
