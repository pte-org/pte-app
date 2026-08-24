sealed class BlueprintDetailEvent {
  const BlueprintDetailEvent();
}

final class BlueprintDetailRequested extends BlueprintDetailEvent {
  const BlueprintDetailRequested(this.publicId);
  final String publicId;
}

final class BlueprintPublishRequested extends BlueprintDetailEvent {
  const BlueprintPublishRequested();
}
