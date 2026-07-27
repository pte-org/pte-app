import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/report_response.dart';
import '../../domain/repositories/report_repository.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';
import '../widgets/skill_score_row.dart';

/// Creates and owns a [ReportBloc] for [attemptPublicId], dispatching the
/// initial [ReportRequested] in `initState` and closing the bloc in
/// `dispose` — same lifecycle shape as Phase 6's `ReadAloudScreen`.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.attemptPublicId, required this.repository});

  final String attemptPublicId;
  final ReportRepository repository;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ReportBloc(repository: widget.repository)..add(ReportRequested(widget.attemptPublicId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.reportScreenTitle)),
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            return switch (state) {
              ReportLoading() => const Center(child: CircularProgressIndicator()),
              ReportNotPublished() => _refreshable(context, const _NotPublishedView()),
              ReportReady(:final report) => _refreshable(context, _ReportReadyView(report: report)),
              ReportError() => _refreshable(context, const _ErrorView()),
            };
          },
        ),
      ),
    );
  }

  Widget _refreshable(BuildContext context, Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReportBloc>().add(ReportRefreshRequested(widget.attemptPublicId));
      },
      child: ListView(padding: const EdgeInsets.all(AppDimensions.spacingMedium), children: [child]),
    );
  }
}

class _NotPublishedView extends StatelessWidget {
  const _NotPublishedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMedium * 4),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(AppStrings.reportNotPublishedTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spacingMedium / 2),
          const Text(AppStrings.reportNotPublishedMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMedium * 4),
      child: Column(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(AppStrings.reportErrorTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spacingMedium / 2),
          const Text(AppStrings.reportErrorMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReportReadyView extends StatelessWidget {
  const _ReportReadyView({required this.report});

  final ReportResponse report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.reportOverallSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        SkillScoreRow(skillScore: report.overall),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(AppStrings.reportCommunicativeSkillsSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        for (final skill in report.communicativeSkills) SkillScoreRow(skillScore: skill),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(AppStrings.reportEnablingSkillsSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        for (final skill in report.enablingSkills) SkillScoreRow(skillScore: skill),
      ],
    );
  }
}
