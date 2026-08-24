import '../../domain/blueprint_types.dart';

sealed class BlueprintBuilderState {
  const BlueprintBuilderState();
}

final class BlueprintBuilderIdle extends BlueprintBuilderState {
  const BlueprintBuilderIdle();
}

final class BlueprintBuilderSubmitting extends BlueprintBuilderState {
  const BlueprintBuilderSubmitting();
}

final class BlueprintBuilderInvalid extends BlueprintBuilderState {
  const BlueprintBuilderInvalid(this.message);
  final String message;
}

final class BlueprintBuilderSuccess extends BlueprintBuilderState {
  const BlueprintBuilderSuccess(this.blueprint);
  final Blueprint blueprint;
}

final class BlueprintBuilderFailure extends BlueprintBuilderState {
  const BlueprintBuilderFailure(this.error);
  final Object error;
}
