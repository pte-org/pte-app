import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/report_response.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<ReportResponse?> fetchReport(String attemptPublicId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reporting/reports/attempts/$attemptPublicId',
      );
      return ReportResponse.fromJson(response.data!);
    } on NotFoundException {
      return null;
    }
  }
}
