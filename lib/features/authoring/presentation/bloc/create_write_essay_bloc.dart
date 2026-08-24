import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authoring_types.dart';
import '../../domain/usecases/create_write_essay.dart';
import 'create_write_essay_event.dart';
import 'create_write_essay_state.dart';

class CreateWriteEssayBloc
    extends Bloc<CreateWriteEssayEvent, CreateWriteEssayState> {
  CreateWriteEssayBloc({required CreateWriteEssay createWriteEssay})
    : _createWriteEssay = createWriteEssay,
      super(const CreateWriteEssayIdle()) {
    on<WriteEssaySubmitted>(_onSubmitted);
  }

  final CreateWriteEssay _createWriteEssay;
  bool _isSubmitting = false;

  Future<void> _onSubmitted(
    WriteEssaySubmitted event,
    Emitter<CreateWriteEssayState> emit,
  ) async {
    if (_isSubmitting) return;
    late final CreateWriteEssayInput input;
    try {
      input = event.input.normalized();
    } on AuthoringValidationException catch (error) {
      emit(CreateWriteEssayInvalid(error.message));
      return;
    }
    _isSubmitting = true;
    emit(const CreateWriteEssaySubmitting());
    try {
      emit(CreateWriteEssaySuccess(await _createWriteEssay(input)));
    } catch (error) {
      emit(CreateWriteEssayFailure(error));
    } finally {
      _isSubmitting = false;
    }
  }
}
