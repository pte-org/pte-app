import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/host_audit_types.dart';
import '../bloc/notification_audit_bloc.dart';
import '../bloc/notification_audit_event.dart';
import '../bloc/notification_audit_state.dart';
import '../formatters/audit_timestamp_formatter.dart';

class NotificationAuditEntryPage extends StatelessWidget {
  const NotificationAuditEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<NotificationAuditBloc>()
            ..add(const NotificationAuditRequested()),
      child: const NotificationAuditPage(),
    );
  }
}

class NotificationAuditPage extends StatelessWidget {
  const NotificationAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationAuditTitle)),
      body: BlocBuilder<NotificationAuditBloc, NotificationAuditState>(
        builder: (context, state) => switch (state) {
          NotificationAuditInitial() ||
          NotificationAuditLoading() => const LoadingView(),
          NotificationAuditEmpty() => const Center(
            child: Text(AppStrings.notificationAuditEmpty),
          ),
          NotificationAuditLoaded(:final items) => ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            itemCount: items.length,
            itemBuilder: (_, index) => _NotificationCard(items[index]),
          ),
          NotificationAuditFailure() => _NotificationFailure(),
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.item);
  final NotificationAudit item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.subject),
        subtitle: Text(
          '${AppStrings.publicIdLabel}: ${item.publicId}\n'
          '${AppStrings.recipientLabel}: ${item.recipientEmail}\n'
          '${AppStrings.notificationTypeLabel}: ${item.notificationType}\n'
          '${AppStrings.deliveryStatusLabel}: ${item.status}\n'
          '${AppStrings.sentAtLabel}: '
          '${AuditTimestampFormatter.format(item.sentAt, missingLabel: AppStrings.notSent)}',
        ),
      ),
    );
  }
}

class _NotificationFailure extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.notificationAuditFailure),
          ElevatedButton(
            onPressed: () => context.read<NotificationAuditBloc>().add(
              const NotificationAuditRequested(),
            ),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
