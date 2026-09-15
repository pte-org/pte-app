import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/dev/mock_backend/mock_backend_adapter.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// A fresh, zero-latency, silent mock backend wired into a real [ApiClient]
/// — each test gets its own seeded state.
({MockBackendAdapter adapter, ApiClient apiClient}) createMockBackend() {
  final adapter = MockBackendAdapter(
    latency: Duration.zero,
    logger: Logger(level: Level.off),
  );
  final apiClient = ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
      ..httpClientAdapter = adapter,
  );
  return (adapter: adapter, apiClient: apiClient);
}

/// Starts (or resumes) an attempt and advances until the server reports it
/// completed, returning every task served along the way.
Future<List<TaskView>> walkAttempt(
  ApiClient apiClient,
  String sessionPublicId,
) async {
  final exam = ExamAttemptRepositoryImpl(apiClient: apiClient);
  var response = await exam.startOrResumeAttempt(sessionPublicId);
  final tasks = <TaskView>[];
  while (!response.completed) {
    tasks.add(response.task!);
    response = await exam.fetchNextTask(response.attemptPublicId);
  }
  return tasks;
}
