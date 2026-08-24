import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/scoring_review_types.dart';
import '../../domain/usecases/manage_scoring.dart';
import 'scoring_review_event.dart';
import 'scoring_review_state.dart';

class ScoringReviewBloc extends Bloc<ScoringReviewEvent, ScoringReviewState> {
  ScoringReviewBloc({
    required LoadPendingReviews loadPendingReviews,
    required ApproveReview approveReview,
    required RequestScoring requestScoring,
    required PublishResults publishResults,
  }) : _loadPendingReviews = loadPendingReviews,
       _approveReview = approveReview,
       _requestScoring = requestScoring,
       _publishResults = publishResults,
       super(const ScoringReviewInitial()) {
    on<ScoringReviewRequested>(_onLoad);
    on<ScoringReviewNextPageRequested>(_onLoadMore);
    on<ScoringReviewApprovalRequested>(_onApprove);
    on<SessionScoringRequested>(_onRequestScoring);
    on<SessionPublishRequested>(_onPublish);
  }

  static const _pageSize = 20;
  final LoadPendingReviews _loadPendingReviews;
  final ApproveReview _approveReview;
  final RequestScoring _requestScoring;
  final PublishResults _publishResults;
  bool _commandRunning = false;

  Future<void> _onLoad(
    ScoringReviewRequested event,
    Emitter<ScoringReviewState> emit,
  ) async {
    emit(const ScoringReviewLoading());
    try {
      emitPage(
        emit,
        await _loadPendingReviews(event.sessionPublicId, 0, _pageSize),
      );
    } catch (error) {
      emit(ScoringReviewFailure(error));
    }
  }

  Future<void> _onLoadMore(
    ScoringReviewNextPageRequested event,
    Emitter<ScoringReviewState> emit,
  ) async {
    final current = _currentPage;
    if (_commandRunning || current == null || !current.hasNextPage) return;
    _commandRunning = true;
    emit(ScoringReviewLoadingMore(current));
    try {
      final next = await _loadPendingReviews(
        event.sessionPublicId,
        current.page + 1,
        current.size,
      );
      emit(
        ScoringReviewLoaded(
          ScoringReviewPage(
            items: List.unmodifiable([...current.items, ...next.items]),
            page: next.page,
            size: next.size,
            totalElements: next.totalElements,
            totalPages: next.totalPages,
          ),
        ),
      );
    } catch (error) {
      emit(ScoringReviewFailure(error, page: current));
    } finally {
      _commandRunning = false;
    }
  }

  Future<void> _onApprove(
    ScoringReviewApprovalRequested event,
    Emitter<ScoringReviewState> emit,
  ) async {
    final current = _currentPage;
    if (_commandRunning || current == null) return;
    _commandRunning = true;
    emit(ScoringReviewRefreshing(current));
    try {
      await _approveReview(event.answerPublicId);
      emitPage(
        emit,
        await _loadPendingReviews(event.sessionPublicId, 0, current.size),
      );
    } catch (error) {
      emit(ScoringReviewFailure(error, page: current));
    } finally {
      _commandRunning = false;
    }
  }

  Future<void> _onRequestScoring(
    SessionScoringRequested event,
    Emitter<ScoringReviewState> emit,
  ) => _runAdminCommand(
    emit,
    () => _requestScoring(event.sessionPublicId),
    'score',
  );

  Future<void> _onPublish(
    SessionPublishRequested event,
    Emitter<ScoringReviewState> emit,
  ) => _runAdminCommand(
    emit,
    () => _publishResults(event.sessionPublicId),
    'publish',
  );

  Future<void> _runAdminCommand(
    Emitter<ScoringReviewState> emit,
    Future<void> Function() command,
    String name,
  ) async {
    final current = _currentPage;
    if (_commandRunning || current == null) return;
    _commandRunning = true;
    emit(ScoringReviewCommandRunning(current));
    try {
      await command();
      emit(ScoringReviewCommandSuccess(current, name));
    } catch (error) {
      emit(ScoringReviewFailure(error, page: current));
    } finally {
      _commandRunning = false;
    }
  }

  ScoringReviewPage? get _currentPage => switch (state) {
    ScoringReviewData(:final page) => page,
    ScoringReviewEmpty(:final page) => page,
    ScoringReviewFailure(:final page) => page,
    _ => null,
  };

  void emitPage(Emitter<ScoringReviewState> emit, ScoringReviewPage page) {
    emit(
      page.items.isEmpty ? ScoringReviewEmpty(page) : ScoringReviewLoaded(page),
    );
  }
}
