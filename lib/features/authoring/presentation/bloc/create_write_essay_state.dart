import '../../domain/authoring_types.dart';

sealed class CreateWriteEssayState {
  const CreateWriteEssayState();
}

final class CreateWriteEssayIdle extends CreateWriteEssayState {
  const CreateWriteEssayIdle();
}

final class CreateWriteEssaySubmitting extends CreateWriteEssayState {
  const CreateWriteEssaySubmitting();
}

final class CreateWriteEssayInvalid extends CreateWriteEssayState {
  const CreateWriteEssayInvalid(this.message);

  final String message;
}

final class CreateWriteEssaySuccess extends CreateWriteEssayState {
  const CreateWriteEssaySuccess(this.question);

  final Question question;
}

final class CreateWriteEssayFailure extends CreateWriteEssayState {
  const CreateWriteEssayFailure(this.error);

  final Object error;
}
