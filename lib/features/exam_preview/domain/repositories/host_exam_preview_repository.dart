import '../entities/host_exam_summary.dart';
import '../entities/preview_snapshot.dart';

abstract interface class HostExamPreviewRepository {
  Future<List<HostExamSummary>> listExams();

  Future<PreviewSnapshot> fetchPreview(String sessionPublicId);
}
