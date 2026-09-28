import 'dart:math';

import 'package:equatable/equatable.dart';

/// Tags a violation by its causal origin so the backend can bucket and
/// deduplicate them. `serverValue` is the exact string that `pte-api`'s
/// `ViolationType` enum expects, so `ViolationEvent` can be serialized
/// directly into the authenticated student security-violation contract
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
    // Unknown server values must remain visible to the retry layer as a
    // terminal compatibility error; remapping them would misrepresent the
    // signal and could send an invalid event forever.
    throw ArgumentError.value(value, 'value', 'Unknown violation type');
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
  ViolationEvent({
    this.id,
    required this.attemptPublicId,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.metadata,
    this.sent = false,
    String? clientEventId,
  }) : clientEventId = clientEventId ?? newClientEventId();

  /// Local Drift row id. `null` until the event is persisted; reporting
  /// logic uses it to flip the `sent` flag without a second lookup.
  final int? id;

  /// Stable idempotency key reused across process restarts and retries.
  final String clientEventId;

  /// Public id of the exam attempt this violation is attributed to.
  final String attemptPublicId;

  final ViolationType type;

  final ViolationSeverity severity;

  final DateTime timestamp;

  /// Free-form JSON envelope for additional context (process name,
  /// window title, etc.). Storing as a JSON string keeps the Drift table
  /// schema stable even as new optional fields are added in later phases.
  final String? metadata;

  /// Sync flag — true after the backend has acknowledged the row.
  final bool sent;

  @override
  List<Object?> get props => [
    id,
    clientEventId,
    attemptPublicId,
    type,
    severity,
    timestamp,
    metadata,
    sent,
  ];

  ViolationEvent copyWith({
    int? id,
    String? clientEventId,
    String? attemptPublicId,
    ViolationType? type,
    ViolationSeverity? severity,
    DateTime? timestamp,
    String? metadata,
    bool? sent,
  }) {
    return ViolationEvent(
      id: id ?? this.id,
      clientEventId: clientEventId ?? this.clientEventId,
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      sent: sent ?? this.sent,
    );
  }

  /// Exact Phase 3 transport contract. The attempt id is carried by the URL,
  /// and client severity is never sent as an authority field.
  Map<String, dynamic> toJson() => {
    'clientEventId': clientEventId,
    'violationType': type.serverValue,
    'clientOccurredAt': timestamp.toUtc().toIso8601String(),
    if (metadata != null) 'detail': boundedDetail(metadata!),
  };

  static const int maxDetailLength = 2048;

  static String boundedDetail(String detail) {
    if (detail.length <= maxDetailLength) return detail;
    return detail.substring(0, maxDetailLength);
  }
}

/// Produces a RFC-4122 version-4 UUID without adding another package for a
/// single client-side idempotency key.
String newClientEventId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

/// A persisted row contains a wire type that this app version does not know.
/// It must be retained for diagnostics and terminalized, never remapped to a
/// different signal type before sending.
class UnknownViolationTypeException implements Exception {
  const UnknownViolationTypeException(this.value);

  final String value;

  @override
  String toString() => 'UnknownViolationTypeException($value)';
}
