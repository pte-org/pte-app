import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authoring_types.dart';
import '../../domain/usecases/create_mc_reading_single.dart';
import 'create_question_event.dart';
import 'create_question_state.dart';

class CreateQuestionBloc
    extends Bloc<CreateQuestionEvent, CreateQuestionState> {
  CreateQuestionBloc({required CreateMcReadingSingle createQuestion})
    : _createQuestion = createQuestion,
      super(const CreateQuestionIdle()) {
    on<CreateQuestionSubmitted>(_onSubmitted);
  }

  final CreateMcReadingSingle _createQuestion;
  bool _isSubmitting = false;

  Future<void> _onSubmitted(
    CreateQuestionSubmitted event,
    Emitter<CreateQuestionState> emit,
  ) async {
    if (_isSubmitting) {
      return;
    }

    late final CreateMcReadingSingleInput input;
    try {
      input = event.input.normalized();
    } on AuthoringValidationException catch (error) {
      emit(CreateQuestionInvalid(error.message));
      return;
    }

    _isSubmitting = true;
    emit(const CreateQuestionSubmitting());
    try {
      emit(CreateQuestionSuccess(await _createQuestion(input)));
    } catch (error) {
      emit(CreateQuestionFailure(error));
    } finally {
      _isSubmitting = false;
    }
  }
}
