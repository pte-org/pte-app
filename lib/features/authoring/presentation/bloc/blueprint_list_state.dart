import '../../domain/blueprint_types.dart';

sealed class BlueprintListState {
  const BlueprintListState();
}

final class BlueprintListInitial extends BlueprintListState {
  const BlueprintListInitial();
}

final class BlueprintListLoading extends BlueprintListState {
  const BlueprintListLoading();
}

final class BlueprintListEmpty extends BlueprintListState {
  const BlueprintListEmpty();
}

final class BlueprintListLoaded extends BlueprintListState {
  const BlueprintListLoaded(this.blueprints);
  final List<Blueprint> blueprints;
}

final class BlueprintListFailure extends BlueprintListState {
  const BlueprintListFailure(this.error);
  final Object error;
}
