import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authoring_types.dart';
import '../../domain/blueprint_types.dart';
import '../../domain/usecases/create_blueprint.dart';
import 'blueprint_builder_event.dart';
import 'blueprint_builder_state.dart';

class BlueprintBuilderBloc
    extends Bloc<BlueprintBuilderEvent, BlueprintBuilderState> {
  BlueprintBuilderBloc({required CreateBlueprint createBlueprint})
    : _createBlueprint = createBlueprint,
      super(const BlueprintBuilderIdle()) {
    on<BlueprintSubmitted>(_onSubmitted);
  }
  final CreateBlueprint _createBlueprint;
  bool _isSubmitting = false;

  Future<void> _onSubmitted(
    BlueprintSubmitted event,
    Emitter<BlueprintBuilderState> emit,
  ) async {
    if (_isSubmitting) return;
    late final CreateBlueprintInput input;
    try {
      input = event.input.normalized();
    } on AuthoringValidationException catch (error) {
      emit(BlueprintBuilderInvalid(error.message));
      return;
    }
    _isSubmitting = true;
    emit(const BlueprintBuilderSubmitting());
    try {
      emit(BlueprintBuilderSuccess(await _createBlueprint(input)));
    } catch (error) {
      emit(BlueprintBuilderFailure(error));
    } finally {
      _isSubmitting = false;
    }
  }
}
