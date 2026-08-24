import '../../domain/authoring_types.dart';

sealed class CreateQuestionState {
  const CreateQuestionState();
}

final class CreateQuestionIdle extends CreateQuestionState {
  const CreateQuestionIdle();
}

final class CreateQuestionSubmitting extends CreateQuestionState {
  const CreateQuestionSubmitting();
}

final class CreateQuestionInvalid extends CreateQuestionState {
  const CreateQuestionInvalid(this.message);

  final String message;
}

final class CreateQuestionSuccess extends CreateQuestionState {
  const CreateQuestionSuccess(this.question);

  final Question question;
}

final class CreateQuestionFailure extends CreateQuestionState {
  const CreateQuestionFailure(this.error);

  final Object error;
}
