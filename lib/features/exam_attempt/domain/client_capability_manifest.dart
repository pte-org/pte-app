import 'package:pte_app/core/constants/task_type_meta.dart';

/// Bounded, declarative capability list sent during attempt preflight/start.
/// It contains semantic keys only; no widget names, source paths or secrets.
class ClientCapabilityManifest {
  const ClientCapabilityManifest(this.capabilities);

  final List<String> capabilities;

  factory ClientCapabilityManifest.fromRegistry() {
    return ClientCapabilityManifest(
      List.unmodifiable(TaskTypeRendererRegistry.capabilityManifest),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'capabilities': capabilities,
  };
}
