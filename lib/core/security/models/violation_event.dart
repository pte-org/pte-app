import 'package:equatable/equatable.dart';

/// Tags a violation by its causal origin so the backend can bucket and
/// deduplicate them. `serverValue` is the exact string that `pte-api`'s
/// `ViolationType` enum expects (Phase 1 added these), so `ViolationEvent`
/// can be serialized directly into `POST /api/proctor/violations`
/// without remapping on the client side.
enum ViolationType {
  fullscreenExit('LOCKDOWN_FULLSCREEN_EXIT'),
  clipboardPaste('LOCKDOWN_CLIPBOARD_PASTE'),
  shortcutBlocked('LOCKDOWN_SHORTCUT_BLOCKED'),
  forbiddenAppDetected('LOCKDOWN_FORBIDDEN_APP_DETECTED');

  const ViolationType(this.serverValue);
  final String serverValue;

  static ViolationType fromServerValue(String value) {
    for (final type in ViolationType.values) {
      if (type.serverValue == value) return type;
    }
    // Unknown server values must not crash — fall back to the most
    // general category so the violation still makes it to storage and
    // the proctor console. Phase 4 / quality gate cross-checks this
    // against Phase 1's enum additions.
    throw ArgumentError.value(value, 'violationType', 'Unknown server value');
  }
}

/// How the violation should be ranked in the proctor dashboard. Mirrors
/// the existing `severity` contract on proctor's existing violation
/// table — 'WARNING' / 'CRITICAL'. LockdownMode.strict escalates
/// detections to critical; standard mode logs at warning.
enum ViolationSeverity {
  warning,
  critical;

  String toServerValue() => name.toUpperCase();
}

class ViolationEvent extends Equatable {
  const ViolationEvent({
    this.id,
    required this.attemptPublicId,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.metadata,
    this.sent = false,
  });

  /// Local Drift row id. `null` until the event is persisted; reporting
  /// logic uses it to flip the `sent` flag without a second lookup.
  final int? id;

  /// Public id of the exam attempt this violation is attributed to.
  final String attemptPublicId;

  final ViolationType type;

  final ViolationSeverity severity;

  final DateTime timestamp;

  /// Free-form JSON envelope for additional context (process name,
  /// window title, etc.). Storing as a JSON string keeps the Drift table
  /// schema stable even as new optional fields are added in later
  /// phases — Phase 1's existing proctor endpoint already accepts
  /// arbitrary metadata.
  final String? metadata;

  /// Sync flag — true after the backend has acknowledged the row.
  final bool sent;

  @override
  List<Object?> get props =>
      [id, attemptPublicId, type, severity, timestamp, metadata, sent];

  ViolationEvent copyWith({
    int? id,
    String? attemptPublicId,
    ViolationType? type,
    ViolationSeverity? severity,
    DateTime? timestamp,
    String? metadata,
    bool? sent,
  }) {
    return ViolationEvent(
      id: id ?? this.id,
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      sent: sent ?? this.sent,
    );
  }

  Map<String, dynamic> toJson() => {
        'violationType': type.serverValue,
        'severity': severity.toServerValue(),
        'timestamp': timestamp.toIso8601String(),
        'attemptPublicId': attemptPublicId,
        if (metadata != null) 'metadata': metadata,
      };
}
