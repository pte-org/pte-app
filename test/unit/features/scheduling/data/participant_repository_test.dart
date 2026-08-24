import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/scheduling/data/repositories/scheduling_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('enroll and assign send only selected public IDs', () async {
    final api = _MockApiClient();
    when(
      () => api.post<Map<String, dynamic>>(
        '/api/scheduling/sessions/session-1/enrollments',
        data: {'studentPublicId': 'student-1'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'publicId': 'enrollment-1',
          'sessionPublicId': 'session-1',
          'studentPublicId': 'student-1',
        },
      ),
    );
    when(
      () => api.post<Map<String, dynamic>>(
        '/api/scheduling/sessions/session-1/proctors',
        data: {'proctorPublicId': 'proctor-1'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'publicId': 'assignment-1',
          'sessionPublicId': 'session-1',
          'proctorPublicId': 'proctor-1',
        },
      ),
    );
    final repository = SchedulingRepositoryImpl(apiClient: api);

    expect(
      (await repository.enrollStudent('session-1', 'student-1')).publicId,
      'enrollment-1',
    );
    expect(
      (await repository.assignProctor('session-1', 'proctor-1')).publicId,
      'assignment-1',
    );
  });
}
