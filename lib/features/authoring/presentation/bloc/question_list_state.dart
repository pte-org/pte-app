import '../../domain/authoring_types.dart';

sealed class QuestionListState {
  const QuestionListState();
}

final class QuestionListInitial extends QuestionListState {
  const QuestionListInitial();
}

final class QuestionListLoading extends QuestionListState {
  const QuestionListLoading();
}

final class QuestionListEmpty extends QuestionListState {
  const QuestionListEmpty();
}

final class QuestionListLoaded extends QuestionListState {
  QuestionListLoaded(List<Question> questions)
    : questions = List.unmodifiable(questions);

  final List<Question> questions;
}

final class QuestionListFailure extends QuestionListState {
  const QuestionListFailure(this.error);

  final Object error;
}
