import '../../domain/authoring_types.dart';

sealed class CreateWriteEssayEvent {
  const CreateWriteEssayEvent();
}

final class WriteEssaySubmitted extends CreateWriteEssayEvent {
  const WriteEssaySubmitted(this.input);

  final CreateWriteEssayInput input;
}
