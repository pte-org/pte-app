import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/host_users/data/repositories/host_user_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('loads tenant-scoped IAM users without tenant query override', () async {
    final api = _MockApiClient();
    when(() => api.get<List<dynamic>>('/api/iam/users')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [
          {
            'publicId': 'user-1',
            'email': 'student@example.com',
            'fullName': 'Student One',
            'tenantId': 'tenant-1',
            'status': 'ACTIVE',
            'roles': ['STUDENT'],
          },
        ],
      ),
    );

    final users = await HostUserRepositoryImpl(apiClient: api).loadUsers();

    expect(users.single.publicId, 'user-1');
    expect(users.single.roles, ['STUDENT']);
    verify(() => api.get<List<dynamic>>('/api/iam/users')).called(1);
  });
}
