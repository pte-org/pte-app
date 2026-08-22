/// The recording workflow's current phase — a single field instead of
/// separate `isRecording`/`hasRecorded` booleans, since the two states are
/// mutually exclusive (never both true at once). Shared by every
/// auto-record speaking task's own state class (`ReadAloudState`,
/// `RepeatSentenceState`) — not Read-Aloud-specific despite having lived
/// alongside `ReadAloudState` originally.
enum RecordingPhase { idle, recording, recorded }
