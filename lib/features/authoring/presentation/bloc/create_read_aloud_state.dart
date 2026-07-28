import '../../domain/authoring_types.dart';

sealed class CreateReadAloudState {
  const CreateReadAloudState();
}

final class CreateReadAloudIdle extends CreateReadAloudState {
  const CreateReadAloudIdle();
}

final class CreateReadAloudSubmitting extends CreateReadAloudState {
  const CreateReadAloudSubmitting();
}

final class CreateReadAloudInvalid extends CreateReadAloudState {
  const CreateReadAloudInvalid(this.message);

  final String message;
}

final class CreateReadAloudSuccess extends CreateReadAloudState {
  const CreateReadAloudSuccess(this.question);

  final Question question;
}

final class CreateReadAloudFailure extends CreateReadAloudState {
  const CreateReadAloudFailure(this.error);

  final Object error;
}
