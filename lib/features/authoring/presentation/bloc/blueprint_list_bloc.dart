import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_blueprints.dart';
import 'blueprint_list_event.dart';
import 'blueprint_list_state.dart';

class BlueprintListBloc extends Bloc<BlueprintListEvent, BlueprintListState> {
  BlueprintListBloc({required LoadBlueprints loadBlueprints})
    : _loadBlueprints = loadBlueprints,
      super(const BlueprintListInitial()) {
    on<BlueprintListRequested>(_onRequested);
  }
  final LoadBlueprints _loadBlueprints;

  Future<void> _onRequested(
    BlueprintListRequested event,
    Emitter<BlueprintListState> emit,
  ) async {
    emit(const BlueprintListLoading());
    try {
      final blueprints = await _loadBlueprints();
      emit(
        blueprints.isEmpty
            ? const BlueprintListEmpty()
            : BlueprintListLoaded(blueprints),
      );
    } catch (error) {
      emit(BlueprintListFailure(error));
    }
  }
}
