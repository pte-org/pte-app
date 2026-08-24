import '../../domain/blueprint_types.dart';

sealed class BlueprintBuilderEvent {
  const BlueprintBuilderEvent();
}

final class BlueprintSubmitted extends BlueprintBuilderEvent {
  const BlueprintSubmitted(this.input);
  final CreateBlueprintInput input;
}
