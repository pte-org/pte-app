import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_list_cubit.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_list_state.dart';

class _MockRepository extends Mock implements HostExamPreviewRepository {}

HostExamSummary _exam(String id, String status, String? snapshot) =>
    HostExamSummary(
      publicId: id,
      sessionCode: 'CODE-$id',
      name: 'Exam $id',
      status: status,
      examVersionPublicId: snapshot,
    );

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  blocTest<HostExamListCubit, HostExamListState>(
    'loads exams and keeps snapshot availability in the domain row',
    setUp: () {
      when(
        () => repository.listExams(),
      ).thenAnswer((_) async => [_exam('ready', 'READY', 'snapshot-1')]);
    },
    build: () => HostExamListCubit(repository: repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<HostExamListLoading>(),
      isA<HostExamListLoaded>().having(
        (state) => state.exams.single.canPreview,
        'canPreview',
        isTrue,
      ),
    ],
  );

  blocTest<HostExamListCubit, HostExamListState>(
    'surfaces repository errors for the common retry UI',
    setUp: () {
      when(() => repository.listExams()).thenThrow(Exception('offline'));
    },
    build: () => HostExamListCubit(repository: repository),
    act: (cubit) => cubit.load(),
    expect: () => [isA<HostExamListLoading>(), isA<HostExamListError>()],
  );
}
