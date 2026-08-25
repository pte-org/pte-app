/// User-facing strings for the "Test Mic and Sound" device-check screen.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class DeviceCheckStrings {
  const DeviceCheckStrings._();

  static const String screenTitle = 'Test Mic and Sound';

  // Microphone section.
  static const String micSectionTitle = 'Test your microphone';
  static const String micInstructionText =
      'Tap Record and say a few words, then tap Stop. Tap Play to hear your recording back.';
  static const String recordButtonLabel = 'Record';
  static const String stopButtonLabel = 'Stop';
  static const String playMyRecordingButtonLabel = 'Play my recording';
  static const String micConfirmPrompt = 'Did you hear yourself clearly?';

  // Sound section.
  static const String soundSectionTitle = 'Test your sound';
  static const String soundInstructionText =
      'Tap Play to hear a short test clip through your speaker or headset.';
  static const String playTestSoundButtonLabel = 'Play test sound';
  static const String soundConfirmPrompt = 'Can you hear this clearly?';

  // Shared confirm buttons.
  static const String confirmYesLabel = 'Yes';
  static const String confirmNoLabel = 'No';
}
