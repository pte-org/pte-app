/// Answer-free result from `POST /api/v1/attempts/preflight`.
class AttemptPreflight {
  const AttemptPreflight({
    required this.canStart,
    required this.missingCapabilities,
    required this.unsupportedTasks,
    this.code,
    this.userMessage,
  });

  final bool canStart;
  final List<String> missingCapabilities;
  final List<UnsupportedTask> unsupportedTasks;
  final String? code;
  final String? userMessage;

  factory AttemptPreflight.fromJson(Map<String, dynamic> json) {
    final rawMissing = json['missingCapabilities'];
    final rawUnsupported = json['unsupportedTasks'];
    return AttemptPreflight(
      canStart: json['canStart'] == true,
      missingCapabilities: rawMissing is List
          ? rawMissing.whereType<String>().toList(growable: false)
          : const <String>[],
      unsupportedTasks: rawUnsupported is List
          ? rawUnsupported
                .whereType<Map>()
                .map(
                  (item) =>
                      UnsupportedTask.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <UnsupportedTask>[],
      code: json['code'] as String?,
      userMessage: json['userMessage'] as String?,
    );
  }
}

class UnsupportedTask {
  const UnsupportedTask({
    this.taskTypeKey,
    this.screenKey,
    this.contractVersion,
    this.reasonCode,
    this.userMessage,
  });

  final String? taskTypeKey;
  final String? screenKey;
  final int? contractVersion;
  final String? reasonCode;
  final String? userMessage;

  factory UnsupportedTask.fromJson(Map<String, dynamic> json) =>
      UnsupportedTask(
        taskTypeKey: json['taskTypeKey'] as String?,
        screenKey: json['screenKey'] as String?,
        contractVersion: json['contractVersion'] is num
            ? (json['contractVersion'] as num).toInt()
            : null,
        reasonCode: json['reasonCode'] as String?,
        userMessage: json['userMessage'] as String?,
      );
}
