import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_questions.dart';
import 'question_list_event.dart';
import 'question_list_state.dart';

class QuestionListBloc extends Bloc<QuestionListEvent, QuestionListState> {
  QuestionListBloc({required LoadQuestions loadQuestions})
    : _loadQuestions = loadQuestions,
      super(const QuestionListInitial()) {
    on<QuestionListRequested>(_onRequested);
    on<QuestionListRetryRequested>(_onRequested);
  }

  final LoadQuestions _loadQuestions;
  int _requestVersion = 0;

  Future<void> _onRequested(
    QuestionListEvent event,
    Emitter<QuestionListState> emit,
  ) async {
    final requestVersion = ++_requestVersion;
    emit(const QuestionListLoading());
    try {
      final questions = await _loadQuestions();
      if (requestVersion != _requestVersion) {
        return;
      }
      emit(
        questions.isEmpty
            ? const QuestionListEmpty()
            : QuestionListLoaded(questions),
      );
    } catch (error) {
      if (requestVersion != _requestVersion) {
        return;
      }
      emit(QuestionListFailure(error));
    }
  }
}
