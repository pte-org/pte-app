import '../../domain/blueprint_types.dart';

sealed class BlueprintDetailState {
  const BlueprintDetailState();
}

final class BlueprintDetailInitial extends BlueprintDetailState {
  const BlueprintDetailInitial();
}

final class BlueprintDetailLoading extends BlueprintDetailState {
  const BlueprintDetailLoading();
}

final class BlueprintDetailReady extends BlueprintDetailState {
  const BlueprintDetailReady(this.blueprint);
  final Blueprint blueprint;
}

final class BlueprintPublishing extends BlueprintDetailState {
  const BlueprintPublishing(this.blueprint);
  final Blueprint blueprint;
}

final class BlueprintPublished extends BlueprintDetailState {
  const BlueprintPublished(this.snapshot);
  final ExamSnapshot snapshot;
}

final class BlueprintDetailFailure extends BlueprintDetailState {
  const BlueprintDetailFailure(this.error, {this.blueprint});
  final Object error;
  final Blueprint? blueprint;
}
