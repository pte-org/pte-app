import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/loading_view.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/core/widgets/status_screen.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';

import '../../data/preview_audio_session.dart';
import '../../domain/entities/host_exam_summary.dart';
import '../../domain/repositories/host_exam_preview_repository.dart';
import '../cubit/host_exam_list_cubit.dart';
import '../cubit/host_exam_list_state.dart';
import 'host_exam_preview_screen.dart';

class HostExamListScreen extends StatelessWidget {
  const HostExamListScreen({super.key, required this.repository});

  final HostExamPreviewRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostExamListCubit(repository: repository)..load(),
      child: _HostExamListView(repository: repository),
    );
  }
}

class _HostExamListView extends StatelessWidget {
  const _HostExamListView({required this.repository});

  final HostExamPreviewRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        title: const Text(ExamPreviewStrings.listTitle),
        actions: [
          IconButton(
            tooltip: ExamPreviewStrings.logout,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<HostExamListCubit, HostExamListState>(
        builder: (context, state) {
          return switch (state) {
            HostExamListInitial() ||
            HostExamListLoading() => const LoadingView(),
            HostExamListError() => StatusScreen(
              icon: Icons.cloud_off,
              title: ExamPreviewStrings.listErrorTitle,
              message: ExamPreviewStrings.listErrorMessage,
              isError: true,
              children: [
                PrimaryButton(
                  label: ExamPreviewStrings.retry,
                  onPressed: context.read<HostExamListCubit>().load,
                ),
              ],
            ),
            HostExamListLoaded(:final exams) => _ExamList(
              exams: exams,
              repository: repository,
            ),
          };
        },
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList({required this.exams, required this.repository});

  final List<HostExamSummary> exams;
  final HostExamPreviewRepository repository;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const StatusScreen(
        icon: Icons.assignment_outlined,
        title: ExamPreviewStrings.emptyListTitle,
        message: ExamPreviewStrings.emptyListMessage,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<HostExamListCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        itemCount: exams.length,
        separatorBuilder: (_, index) =>
            const SizedBox(height: AppDimensions.spacingSm),
        itemBuilder: (context, index) =>
            _ExamCard(exam: exams[index], repository: repository),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.repository});

  final HostExamSummary exam;
  final HostExamPreviewRepository repository;

  @override
  Widget build(BuildContext context) {
    final canPreview = exam.canPreview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    ExamPreviewStrings.sessionSummary(
                      exam.sessionCode ?? exam.publicId,
                      exam.status,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    exam.hasSnapshot
                        ? ExamPreviewStrings.snapshotAvailable
                        : ExamPreviewStrings.snapshotUnavailable,
                    style: TextStyle(
                      color: canPreview
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            PrimaryButton(
              label: ExamPreviewStrings.preview,
              onPressed: canPreview ? () => _openPreview(context) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HostExamPreviewScreen(
          sessionPublicId: exam.publicId,
          repository: repository,
          mediaSession: GetIt.instance<PreviewAudioSession>(),
        ),
      ),
    );
  }
}
