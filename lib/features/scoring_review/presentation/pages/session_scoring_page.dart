import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/scoring_review_types.dart';
import '../bloc/scoring_review_bloc.dart';
import '../bloc/scoring_review_event.dart';
import '../bloc/scoring_review_state.dart';

class SessionScoringPage extends StatelessWidget {
  const SessionScoringPage({
    required this.sessionPublicId,
    required this.isAdmin,
    super.key,
  });

  final String sessionPublicId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scoringReviewTitle)),
      body: BlocConsumer<ScoringReviewBloc, ScoringReviewState>(
        listener: (context, state) {
          if (state is ScoringReviewCommandSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.scoringCommandSuccess)),
            );
          } else if (state case ScoringReviewFailure(:final error)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
          }
        },
        builder: (context, state) => switch (state) {
          ScoringReviewInitial() ||
          ScoringReviewLoading() => const LoadingView(),
          ScoringReviewEmpty(:final page) => _ScoringBody(
            page: page,
            sessionPublicId: sessionPublicId,
            isAdmin: isAdmin,
          ),
          ScoringReviewData(:final page) => _ScoringBody(
            page: page,
            sessionPublicId: sessionPublicId,
            isAdmin: isAdmin,
            busy:
                state is ScoringReviewRefreshing ||
                state is ScoringReviewCommandRunning,
            loadingMore: state is ScoringReviewLoadingMore,
          ),
          ScoringReviewFailure(:final page) when page != null => _ScoringBody(
            page: page,
            sessionPublicId: sessionPublicId,
            isAdmin: isAdmin,
          ),
          ScoringReviewFailure() => _LoadFailure(
            sessionPublicId: sessionPublicId,
          ),
        },
      ),
    );
  }

  String _errorMessage(Object error) => switch (error) {
    ConflictException() => AppStrings.scoringConflict,
    _ => AppStrings.scoringCommandFailure,
  };
}

class _ScoringBody extends StatelessWidget {
  const _ScoringBody({
    required this.page,
    required this.sessionPublicId,
    required this.isAdmin,
    this.busy = false,
    this.loadingMore = false,
  });

  final ScoringReviewPage page;
  final String sessionPublicId;
  final bool isAdmin;
  final bool busy;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      children: [
        if (isAdmin)
          Wrap(
            spacing: AppDimensions.spacingMedium,
            children: [
              ElevatedButton(
                onPressed: busy
                    ? null
                    : () => _confirmAdminCommand(context, publish: false),
                child: const Text(AppStrings.requestScoring),
              ),
              ElevatedButton(
                onPressed: busy
                    ? null
                    : () => _confirmAdminCommand(context, publish: true),
                child: const Text(AppStrings.publishResults),
              ),
            ],
          ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(
          AppStrings.pendingReviewsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (page.items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppDimensions.spacingMedium),
            child: Text(AppStrings.pendingReviewsEmpty),
          )
        else
          for (final answer in page.items)
            Card(
              child: ListTile(
                title: Text('${AppStrings.taskTypeLabel}: ${answer.taskType}'),
                subtitle: Text(
                  '${AppStrings.attemptLabel}: ${answer.attemptPublicId}\n'
                  '${AppStrings.rawScoreLabel}: ${answer.rawScore ?? '-'}',
                ),
                trailing: ElevatedButton(
                  onPressed: busy
                      ? null
                      : () => _confirmReview(context, answer.answerPublicId),
                  child: const Text(AppStrings.approveReview),
                ),
              ),
            ),
        if (page.hasNextPage)
          ElevatedButton(
            onPressed: loadingMore
                ? null
                : () => context.read<ScoringReviewBloc>().add(
                    ScoringReviewNextPageRequested(sessionPublicId),
                  ),
            child: Text(
              loadingMore
                  ? AppStrings.scoringCommandSuccess
                  : AppStrings.loadMore,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAdminCommand(
    BuildContext context, {
    required bool publish,
  }) async {
    final confirmed = await _confirm(context);
    if (!context.mounted || !confirmed) return;
    context.read<ScoringReviewBloc>().add(
      publish
          ? SessionPublishRequested(sessionPublicId)
          : SessionScoringRequested(sessionPublicId),
    );
  }

  Future<void> _confirmReview(
    BuildContext context,
    String answerPublicId,
  ) async {
    final confirmed = await _confirm(
      context,
      title: AppStrings.reviewConfirmation,
    );
    if (!context.mounted || !confirmed) return;
    context.read<ScoringReviewBloc>().add(
      ScoringReviewApprovalRequested(sessionPublicId, answerPublicId),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    String title = AppStrings.sessionTransitionConfirmation,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(AppStrings.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.sessionPublicId});
  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.scoringReviewsLoadFailure),
          ElevatedButton(
            onPressed: () => context.read<ScoringReviewBloc>().add(
              ScoringReviewRequested(sessionPublicId),
            ),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
