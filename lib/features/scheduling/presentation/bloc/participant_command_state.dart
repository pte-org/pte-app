sealed class ParticipantCommandState {
  const ParticipantCommandState();
}

final class ParticipantIdle extends ParticipantCommandState {
  const ParticipantIdle();
}

final class ParticipantSubmitting extends ParticipantCommandState {
  const ParticipantSubmitting();
}

final class ParticipantSuccess extends ParticipantCommandState {
  const ParticipantSuccess(this.result);
  final Object result;
}

final class ParticipantFailure extends ParticipantCommandState {
  const ParticipantFailure(this.error);
  final Object error;
}
