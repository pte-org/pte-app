import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/authoring/data/repositories/authoring_repository_impl.dart';
import 'package:pte_app/features/authoring/domain/blueprint_types.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late AuthoringRepositoryImpl repository;

  Map<String, dynamic> blueprintJson() => {
    'publicId': 'bp-1',
    'name': 'Exam',
    'tenantId': 'tenant-1',
    'status': 'DRAFT',
    'items': [
      {'questionPublicId': 'q-1', 'section': 'READING', 'orderIndex': 0},
    ],
  };
  Map<String, dynamic> snapshotJson() => {
    'publicId': 'snap-1',
    'name': 'Exam',
    'version': 1,
    'sourceBlueprintPublicId': 'bp-1',
    'tenantId': 'tenant-1',
    'items': [
      {
        'orderIndex': 0,
        'section': 'READING',
        'taskType': 'MC_READING_SINGLE',
        'title': 'Question',
      },
    ],
  };

  setUp(() {
    api = _MockApiClient();
    repository = AuthoringRepositoryImpl(apiClient: api);
  });

  test('list/get/create use exact blueprint gateway contracts', () async {
    when(() => api.get<List<dynamic>>('/api/authoring/blueprints')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [blueprintJson()],
      ),
    );
    when(
      () => api.get<Map<String, dynamic>>('/api/authoring/blueprints/bp-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: blueprintJson(),
      ),
    );
    Object? payload;
    when(
      () => api.post<Map<String, dynamic>>(
        '/api/authoring/blueprints',
        data: any(named: 'data'),
      ),
    ).thenAnswer((invocation) async {
      payload = invocation.namedArguments[#data];
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: blueprintJson(),
      );
    });

    expect((await repository.loadBlueprints()).single.publicId, 'bp-1');
    expect((await repository.loadBlueprint('bp-1')).name, 'Exam');
    await repository.createBlueprint(
      CreateBlueprintInput(
        name: 'Exam',
        items: const [
          BlueprintItemInput(
            questionPublicId: 'q-1',
            section: 'READING',
            orderIndex: 0,
          ),
        ],
      ),
    );
    expect(payload, {
      'name': 'Exam',
      'items': [
        {'questionPublicId': 'q-1', 'section': 'READING', 'orderIndex': 0},
      ],
    });
  });

  test('publish and snapshot detail use exact gateway paths', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        '/api/authoring/blueprints/bp-1/publish',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: snapshotJson(),
      ),
    );
    when(
      () => api.get<Map<String, dynamic>>('/api/authoring/snapshots/snap-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: snapshotJson(),
      ),
    );

    expect((await repository.publishBlueprint('bp-1')).publicId, 'snap-1');
    expect((await repository.loadSnapshot('snap-1')).version, 1);
  });
}
