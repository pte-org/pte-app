/// Answer-free result from `POST /api/v1/attempts/preflight`.
class AttemptPreflight {
  const AttemptPreflight({
    required this.canStart,
    required this.missingCapabilities,
    this.code,
    this.userMessage,
  });

  final bool canStart;
  final List<String> missingCapabilities;
  final String? code;
  final String? userMessage;

  factory AttemptPreflight.fromJson(Map<String, dynamic> json) {
    final rawMissing = json['missingCapabilities'];
    return AttemptPreflight(
      canStart: json['canStart'] == true,
      missingCapabilities: rawMissing is List
          ? rawMissing.whereType<String>().toList(growable: false)
          : const <String>[],
      code: json['code'] as String?,
      userMessage: json['userMessage'] as String?,
    );
  }
}
