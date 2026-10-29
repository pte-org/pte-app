import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/host_exam_preview_repository.dart';
import 'host_exam_list_state.dart';

class HostExamListCubit extends Cubit<HostExamListState> {
  HostExamListCubit({required HostExamPreviewRepository repository})
    : _repository = repository,
      super(const HostExamListInitial());

  final HostExamPreviewRepository _repository;

  Future<void> load() async {
    emit(const HostExamListLoading());
    try {
      final exams = await _repository.listExams();
      if (!isClosed) emit(HostExamListLoaded(List.unmodifiable(exams)));
    } catch (error) {
      if (!isClosed) emit(HostExamListError(error));
    }
  }
}
