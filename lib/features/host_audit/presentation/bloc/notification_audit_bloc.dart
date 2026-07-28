import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_host_audit.dart';
import 'notification_audit_event.dart';
import 'notification_audit_state.dart';

class NotificationAuditBloc
    extends Bloc<NotificationAuditEvent, NotificationAuditState> {
  NotificationAuditBloc({required LoadNotifications loadNotifications})
    : _loadNotifications = loadNotifications,
      super(const NotificationAuditInitial()) {
    on<NotificationAuditRequested>(_onLoad);
  }

  final LoadNotifications _loadNotifications;

  Future<void> _onLoad(
    NotificationAuditRequested event,
    Emitter<NotificationAuditState> emit,
  ) async {
    emit(const NotificationAuditLoading());
    try {
      final items = await _loadNotifications();
      emit(
        items.isEmpty
            ? const NotificationAuditEmpty()
            : NotificationAuditLoaded(items),
      );
    } catch (error) {
      emit(NotificationAuditFailure(error));
    }
  }
}
