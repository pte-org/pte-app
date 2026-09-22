import 'package:pte_app/core/constants/task_type_meta.dart';

/// Bounded, declarative capability list sent during attempt preflight/start.
/// It contains semantic keys only; no widget names, source paths or secrets.
class ClientCapabilityManifest {
  const ClientCapabilityManifest({
    required this.capabilities,
    required this.appVersion,
    required this.supportedContracts,
  });

  final List<String> capabilities;
  final String appVersion;
  final List<SupportedRuntimeContract> supportedContracts;

  factory ClientCapabilityManifest.fromRegistry() {
    return ClientCapabilityManifest(
      capabilities: List.unmodifiable(
        TaskTypeRendererRegistry.capabilityManifest,
      ),
      appVersion: '1.0.0',
      supportedContracts: List.unmodifiable(
        TaskTypeRendererRegistry.all
            .expand(
              (registration) => registration.supportedContractVersions.map(
                (version) => SupportedRuntimeContract(
                  screenKey: registration.screenKey,
                  contractVersion: version,
                  answerSchemaVersion:
                      registration.supportedSchemaVersions.toList()..sort(),
                  scoringProfileVersion:
                      registration.supportedScoringProfileVersions.toList()
                        ..sort(),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'capabilities': capabilities,
    'appVersion': appVersion,
    'supportedContracts': supportedContracts
        .map((contract) => contract.toJson())
        .toList(),
  };
}

class SupportedRuntimeContract {
  const SupportedRuntimeContract({
    required this.screenKey,
    required this.contractVersion,
    required this.answerSchemaVersion,
    required this.scoringProfileVersion,
  });

  final String screenKey;
  final int contractVersion;
  final List<int> answerSchemaVersion;
  final List<int> scoringProfileVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'screenKey': screenKey,
    'contractVersion': contractVersion,
    // The server accepts one descriptor per supported combination. Keep the
    // wire payload compact while truthfully advertising every supported pair.
    'answerSchemaVersion': answerSchemaVersion.first,
    'scoringProfileVersion': scoringProfileVersion.first,
  };
}
