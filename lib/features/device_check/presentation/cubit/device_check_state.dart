import 'package:equatable/equatable.dart';

/// Mic sub-flow phase — `playedBack` is distinct from `playingBack` (the
/// point at which the confirm Yes/No prompt becomes visible, once playback
/// has actually finished, not merely started).
enum MicCheckPhase { idle, recording, recorded, playingBack, playedBack }

/// Sound sub-flow phase — same `played`-after-`playing` distinction as
/// [MicCheckPhase], for the same reason (confirm prompt only appears once
/// playback has actually finished).
enum SoundCheckPhase { idle, playing, played }

/// Two fully independent sub-flows (mic test, sound test) in one state —
/// acting on one (recording, playing back, confirming, or resetting on
/// "No") never touches the other's fields. No shared `copyWith`: every
/// cubit emission constructs the next state explicitly, threading the
/// other sub-flow's current fields through unchanged, since a generic
/// `field ?? this.field` copyWith can't distinguish "leave unchanged" from
/// "reset to null" for the nullable confirm fields.
class DeviceCheckState extends Equatable {
  const DeviceCheckState({
    this.micPhase = MicCheckPhase.idle,
    this.micConfirmedHeardClearly,
    this.micErrorMessage,
    this.soundPhase = SoundCheckPhase.idle,
    this.soundConfirmedHeardClearly,
  });

  final MicCheckPhase micPhase;

  /// `null` = not yet answered, `true`/`false` = the candidate's Yes/No
  /// answer to "Did you hear yourself clearly?".
  final bool? micConfirmedHeardClearly;

  final String? micErrorMessage;

  final SoundCheckPhase soundPhase;

  /// `null` = not yet answered, `true`/`false` = the candidate's Yes/No
  /// answer to "Can you hear this clearly?".
  final bool? soundConfirmedHeardClearly;

  bool get isComplete =>
      micConfirmedHeardClearly == true && soundConfirmedHeardClearly == true;

  @override
  List<Object?> get props => [
    micPhase,
    micConfirmedHeardClearly,
    micErrorMessage,
    soundPhase,
    soundConfirmedHeardClearly,
  ];
}
