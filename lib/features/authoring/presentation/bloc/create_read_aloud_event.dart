import '../../domain/authoring_types.dart';

sealed class CreateReadAloudEvent {
  const CreateReadAloudEvent();
}

final class ReadAloudSubmitted extends CreateReadAloudEvent {
  const ReadAloudSubmitted(this.input);

  final CreateReadAloudInput input;
}
