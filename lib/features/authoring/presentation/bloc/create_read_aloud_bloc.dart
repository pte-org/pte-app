import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authoring_types.dart';
import '../../domain/usecases/create_read_aloud.dart';
import 'create_read_aloud_event.dart';
import 'create_read_aloud_state.dart';

class CreateReadAloudBloc
    extends Bloc<CreateReadAloudEvent, CreateReadAloudState> {
  CreateReadAloudBloc({required CreateReadAloud createReadAloud})
    : _createReadAloud = createReadAloud,
      super(const CreateReadAloudIdle()) {
    on<ReadAloudSubmitted>(_onSubmitted);
  }

  final CreateReadAloud _createReadAloud;
  bool _isSubmitting = false;

  Future<void> _onSubmitted(
    ReadAloudSubmitted event,
    Emitter<CreateReadAloudState> emit,
  ) async {
    if (_isSubmitting) return;
    late final CreateReadAloudInput input;
    try {
      input = event.input.normalized();
    } on AuthoringValidationException catch (error) {
      emit(CreateReadAloudInvalid(error.message));
      return;
    }
    _isSubmitting = true;
    emit(const CreateReadAloudSubmitting());
    try {
      emit(CreateReadAloudSuccess(await _createReadAloud(input)));
    } catch (error) {
      emit(CreateReadAloudFailure(error));
    } finally {
      _isSubmitting = false;
    }
  }
}
