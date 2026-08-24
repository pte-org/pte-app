import '../../domain/authoring_types.dart';

sealed class CreateQuestionEvent {
  const CreateQuestionEvent();
}

final class CreateQuestionSubmitted extends CreateQuestionEvent {
  const CreateQuestionSubmitted(this.input);

  final CreateMcReadingSingleInput input;
}
