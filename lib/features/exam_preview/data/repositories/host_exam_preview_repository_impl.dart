import '../../constants/exam_preview_api_paths.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:pte_app/core/network/api_client.dart';

import '../../domain/entities/host_exam_summary.dart';
import '../../domain/entities/preview_snapshot.dart';
import '../../domain/repositories/host_exam_preview_repository.dart';
import '../models/host_exam_summary_model.dart';
import '../models/preview_snapshot_model.dart';

class HostExamPreviewRepositoryImpl implements HostExamPreviewRepository {
  HostExamPreviewRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<HostExamSummary>> listExams() async {
    final response = await _apiClient.get<List<dynamic>>(
      ExamPreviewApiPaths.sessions,
    );
    final data = response.data;
    if (data == null) return const [];
    return data
        .whereType<Map>()
        .map(
          (raw) =>
              HostExamSummaryModel.fromJson(Map<String, dynamic>.from(raw)),
        )
        .toList(growable: false);
  }

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async {
    final id = sessionPublicId.trim();
    if (id.isEmpty) {
      throw const FormatException(ExamPreviewStrings.sessionIdRequired);
    }
    final response = await _apiClient.get<Map<String, dynamic>>(
      ExamPreviewApiPaths.snapshot(id),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(ExamPreviewStrings.emptyResponse);
    }
    return PreviewSnapshotModel.fromJson(data);
  }
}
