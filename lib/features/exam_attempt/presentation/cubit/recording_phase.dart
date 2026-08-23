/// The recording workflow's current phase — a single field instead of
/// separate `isRecording`/`hasRecorded` booleans, since the two states are
/// mutually exclusive (never both true at once). Used by `AutoRecordState`,
/// shared by every auto-record speaking task's screen (Read Aloud, Repeat
/// Sentence, Describe Image).
enum RecordingPhase { idle, recording, recorded }
