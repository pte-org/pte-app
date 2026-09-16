import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/report/domain/report_response.dart';
import 'package:pte_app/features/report/domain/repositories/report_repository.dart';
import 'package:pte_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:pte_app/features/report/presentation/bloc/report_event.dart';
import 'package:pte_app/features/report/presentation/bloc/report_state.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

ReportResponse _report() {
  const overall = SkillScoreResponse(skill: 'Overall', score: 65, sufficientData: true);
  return const ReportResponse(
    attemptPublicId: 'attempt-1',
    sessionPublicId: 'session-1',
    published: true,
    publishedAt: null,
    overall: overall,
    communicativeSkills: [],
  );
}

void main() {
  late _MockReportRepository repository;

  setUp(() {
    repository = _MockReportRepository();
  });

  ReportBloc buildBloc() => ReportBloc(repository: repository);

  group('Step 7 — a mocked 404 (repository returns null) produces ReportNotPublished, never ReportError', () {
    blocTest<ReportBloc, ReportState>(
      'ReportRequested with a null repository result emits ReportLoading then ReportNotPublished',
      setUp: () {
        when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => null);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ReportRequested('attempt-1')),
      expect: () => [isA<ReportLoading>(), isA<ReportNotPublished>()],
      verify: (_) {
        verify(() => repository.fetchReport('attempt-1')).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'ReportRefreshRequested with a null repository result also routes to ReportNotPublished, not ReportError',
      setUp: () {
        when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => null);
      },
      build: buildBloc,
      seed: () => ReportReady(_report()),
      act: (bloc) => bloc.add(const ReportRefreshRequested('attempt-1')),
      expect: () => [isA<ReportLoading>(), isA<ReportNotPublished>()],
    );
  });

  group('Step 8 — a mocked non-404 failure produces ReportError, distinct from ReportNotPublished', () {
    blocTest<ReportBloc, ReportState>(
      'a thrown NetworkException emits ReportLoading then ReportError carrying that exception',
      setUp: () {
        when(() => repository.fetchReport('attempt-1')).thenThrow(const NetworkException('connection refused'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ReportRequested('attempt-1')),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportError>().having((s) => s.error, 'error', isA<NetworkException>()),
      ],
    );

    blocTest<ReportBloc, ReportState>(
      'a thrown UnknownApiException (simulating a 500) emits ReportError, not ReportNotPublished',
      setUp: () {
        when(() => repository.fetchReport('attempt-1')).thenThrow(const UnknownApiException('server error'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ReportRequested('attempt-1')),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportError>().having((s) => s.error, 'error', isA<UnknownApiException>()),
      ],
    );
  });

  blocTest<ReportBloc, ReportState>(
    'a successful (non-null) fetch emits ReportReady carrying the parsed report',
    setUp: () {
      when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => _report());
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ReportRequested('attempt-1')),
    expect: () => [
      isA<ReportLoading>(),
      isA<ReportReady>().having((s) => s.report.attemptPublicId, 'attemptPublicId', 'attempt-1'),
    ],
  );

  test('ReportBloc starts in ReportLoading before any event is dispatched', () {
    expect(buildBloc().state, isA<ReportLoading>());
  });
}
