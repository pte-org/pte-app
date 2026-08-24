import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_banner.dart';
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
  const ReportScreen({super.key, required this.attemptPublicId, required this.repository, this.onBack});

  final String attemptPublicId;
  final ReportRepository repository;

  /// Dev-testing affordance to reset the attempt and return to session
  /// entry. Rendered as the `AppBar`'s own `leading` slot (not a floating
  /// widget overlaid on top) so it never covers the title text.
  final VoidCallback? onBack;

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
        appBar: AppBar(
          title: const Text(AppStrings.reportScreenTitle),
          leading: widget.onBack == null
              ? null
              : IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        ),
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            return switch (state) {
              ReportLoading() => const LoadingView(),
              ReportNotPublished() => _refreshable(
                context,
                const StatusBanner(
                  icon: Icons.hourglass_empty,
                  title: AppStrings.reportNotPublishedTitle,
                  message: AppStrings.reportNotPublishedMessage,
                ),
              ),
              ReportReady(:final report) => _refreshable(context, _ReportReadyView(report: report)),
              ReportError() => _refreshable(
                context,
                const StatusBanner(
                  icon: Icons.error_outline,
                  title: AppStrings.reportErrorTitle,
                  message: AppStrings.reportErrorMessage,
                  isError: true,
                ),
              ),
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
