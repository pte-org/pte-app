sealed class QuestionListEvent {
  const QuestionListEvent();
}

final class QuestionListRequested extends QuestionListEvent {
  const QuestionListRequested();
}

final class QuestionListRetryRequested extends QuestionListEvent {
  const QuestionListRetryRequested();
}
