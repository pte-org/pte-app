import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/pages/host_exam_list_screen.dart';

class _FakeRepository implements HostExamPreviewRepository {
  _FakeRepository(this.exams);

  final List<HostExamSummary> exams;

  @override
  Future<List<HostExamSummary>> listExams() async => exams;

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('shows snapshot availability and disables draft preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HostExamListScreen(
          repository: _FakeRepository([
            const HostExamSummary(
              publicId: 'ready',
              sessionCode: 'READY-1',
              name: 'Ready exam',
              status: 'READY',
              examVersionPublicId: 'snapshot-1',
            ),
            const HostExamSummary(
              publicId: 'draft',
              sessionCode: 'DRAFT-1',
              name: 'Draft exam',
              status: 'DRAFT',
              examVersionPublicId: null,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready exam'), findsOneWidget);
    expect(find.text('Snapshot available'), findsOneWidget);
    expect(
      find.text('Preview unavailable until a snapshot is generated'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Preview'), findsNWidgets(2));
    final buttons = tester.widgetList<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Preview'),
    );
    expect(buttons.first.onPressed, isNotNull);
    expect(buttons.last.onPressed, isNull);
  });

  testWidgets('renders the common retry surface after a list failure', (
    tester,
  ) async {
    final repository = _FailingRepository();
    await tester.pumpWidget(
      MaterialApp(home: HostExamListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load exams'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _FailingRepository extends _FakeRepository {
  _FailingRepository() : super(const []);

  @override
  Future<List<HostExamSummary>> listExams() async {
    throw Exception('offline');
  }
}
