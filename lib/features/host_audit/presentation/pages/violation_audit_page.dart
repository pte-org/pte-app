import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/host_audit_types.dart';
import '../bloc/violation_audit_bloc.dart';
import '../bloc/violation_audit_event.dart';
import '../bloc/violation_audit_state.dart';
import '../formatters/audit_timestamp_formatter.dart';

class ViolationAuditEntryPage extends StatelessWidget {
  const ViolationAuditEntryPage({required this.sessionPublicId, super.key});

  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<ViolationAuditBloc>()
            ..add(ViolationAuditRequested(sessionPublicId)),
      child: ViolationAuditPage(sessionPublicId: sessionPublicId),
    );
  }
}

class ViolationAuditPage extends StatelessWidget {
  const ViolationAuditPage({required this.sessionPublicId, super.key});

  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.violationAuditTitle)),
      body: BlocBuilder<ViolationAuditBloc, ViolationAuditState>(
        builder: (context, state) => switch (state) {
          ViolationAuditInitial() ||
          ViolationAuditLoading() => const LoadingView(),
          ViolationAuditEmpty() => const Center(
            child: Text(AppStrings.violationAuditEmpty),
          ),
          ViolationAuditLoaded(:final items) => ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            itemCount: items.length,
            itemBuilder: (_, index) => _ViolationCard(items[index]),
          ),
          ViolationAuditFailure() => _ViolationFailure(
            sessionPublicId: sessionPublicId,
          ),
        },
      ),
    );
  }
}

class _ViolationCard extends StatelessWidget {
  const _ViolationCard(this.item);
  final ViolationAuditEvent item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.violationTypeLabel}: ${item.violationType}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${AppStrings.publicIdLabel}: ${item.publicId}'),
            Text('${AppStrings.attemptLabel}: ${item.attemptPublicId}'),
            Text('${AppStrings.violationDetailLabel}: ${item.detail}'),
            Text('${AppStrings.sequenceLabel}: ${item.sequenceNo}'),
            Text(
              '${AppStrings.detectedAtLabel}: '
              '${AuditTimestampFormatter.format(item.detectedAt, missingLabel: AppStrings.notSent)}',
            ),
            const Text(AppStrings.integrityHashLabel),
            SelectableText(item.hash),
          ],
        ),
      ),
    );
  }
}

class _ViolationFailure extends StatelessWidget {
  const _ViolationFailure({required this.sessionPublicId});
  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.violationAuditFailure),
          ElevatedButton(
            onPressed: () => context.read<ViolationAuditBloc>().add(
              ViolationAuditRequested(sessionPublicId),
            ),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
