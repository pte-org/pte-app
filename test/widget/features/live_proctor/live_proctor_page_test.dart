import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_bloc.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_event.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_state.dart';
import 'package:pte_app/features/live_proctor/presentation/pages/live_proctor_page.dart';

class _MockLiveProctorBloc extends MockBloc<LiveProctorEvent, LiveProctorState>
    implements LiveProctorBloc {}

void main() {
  Widget subject({required bool canControl}) {
    final bloc = _MockLiveProctorBloc();
    whenListen(
      bloc,
      const Stream<LiveProctorState>.empty(),
      initialState: LiveProctorState(
        status: LiveProctorStatus.connected,
        canControl: canControl,
      ),
    );
    addTearDown(bloc.close);
    return MaterialApp(
      home: BlocProvider<LiveProctorBloc>.value(
        value: bloc,
        child: LiveProctorPage(canControl: canControl),
      ),
    );
  }

  testWidgets('HOST_ADMIN view is read-only', (tester) async {
    await tester.pumpWidget(subject(canControl: false));

    expect(find.text(AppStrings.liveReadOnlyNotice), findsOneWidget);
    expect(find.text(AppStrings.liveForceSubmit), findsNothing);
    expect(find.text(AppStrings.liveFlagViolation), findsNothing);
  });

  testWidgets('PROCTOR view exposes guarded command controls', (tester) async {
    await tester.pumpWidget(subject(canControl: true));

    expect(find.text(AppStrings.liveReadOnlyNotice), findsNothing);
    expect(find.text(AppStrings.liveForceSubmit), findsOneWidget);
    expect(find.text(AppStrings.liveFlagViolation), findsOneWidget);
  });
}
