import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/re_order_paragraphs_list.dart';

class _Dao extends Mock implements AnswerOutboxDao {}

void main() {
  late ReOrderParagraphsCubit cubit;
  setUp(() {
    final dao = _Dao();
    when(
      () => dao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    cubit = ReOrderParagraphsCubit(
      outboxDao: dao,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      initialOrder: const [
        TaskOption(text: 'Second.', orderIndex: '9'),
        TaskOption(text: 'First.', orderIndex: '4'),
      ],
    );
  });
  tearDown(() => cubit.close());
  Widget subject() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider.value(
          value: cubit,
          child: const ReOrderParagraphsList(),
        ),
      ),
    ),
  );
  testWidgets('transfer, reorder and return keep each paragraph exactly once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    expect(cubit.state.currentOrder, isEmpty);
    for (final label in ['First.', 'Second.']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.tap(find.byTooltip('Move to Target'));
      await tester.pump();
    }
    expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['4', '9']);
    await tester.tap(find.byTooltip('Move up'));
    await tester.pump();
    expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['9', '4']);
    await tester.tap(find.byTooltip('Move down'));
    await tester.pump();
    expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['4', '9']);
    await tester.tap(find.byTooltip('Move to Source'));
    await tester.pump();
    expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['4']);
    expect(find.text('First.'), findsOneWidget);
    expect(find.text('Second.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('drag from Source into empty Target updates saved answer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    final source = tester.getCenter(find.text('Second.'));
    final target = tester.getCenter(
      find.byKey(const ValueKey('paragraphTarget')),
    );
    final gesture = await tester.startGesture(source);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['9']);
    expect(find.text('Second.'), findsOneWidget);
  });
  testWidgets('Source and Target stack on narrow screens without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    expect(
      tester.getTopLeft(find.text('Target')).dy,
      greaterThan(tester.getTopLeft(find.text('Source')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
