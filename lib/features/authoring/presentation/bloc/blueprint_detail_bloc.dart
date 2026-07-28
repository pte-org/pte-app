import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/blueprint_types.dart';
import '../../domain/usecases/load_blueprint.dart';
import '../../domain/usecases/publish_blueprint.dart';
import 'blueprint_detail_event.dart';
import 'blueprint_detail_state.dart';

class BlueprintDetailBloc
    extends Bloc<BlueprintDetailEvent, BlueprintDetailState> {
  BlueprintDetailBloc({
    required LoadBlueprint loadBlueprint,
    required PublishBlueprint publishBlueprint,
  }) : _loadBlueprint = loadBlueprint,
       _publishBlueprint = publishBlueprint,
       super(const BlueprintDetailInitial()) {
    on<BlueprintDetailRequested>(_onLoad);
    on<BlueprintPublishRequested>(_onPublish);
  }
  final LoadBlueprint _loadBlueprint;
  final PublishBlueprint _publishBlueprint;
  Blueprint? _blueprint;
  bool _isPublishing = false;

  Future<void> _onLoad(
    BlueprintDetailRequested event,
    Emitter<BlueprintDetailState> emit,
  ) async {
    emit(const BlueprintDetailLoading());
    try {
      _blueprint = await _loadBlueprint(event.publicId);
      emit(BlueprintDetailReady(_blueprint!));
    } catch (error) {
      emit(BlueprintDetailFailure(error));
    }
  }

  Future<void> _onPublish(
    BlueprintPublishRequested event,
    Emitter<BlueprintDetailState> emit,
  ) async {
    if (_isPublishing || _blueprint == null) return;
    _isPublishing = true;
    emit(BlueprintPublishing(_blueprint!));
    try {
      emit(BlueprintPublished(await _publishBlueprint(_blueprint!.publicId)));
    } catch (error) {
      emit(BlueprintDetailFailure(error, blueprint: _blueprint));
    } finally {
      _isPublishing = false;
    }
  }
}
