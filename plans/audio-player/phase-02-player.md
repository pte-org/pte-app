# Phase 2: Player Implementation

**Stories Covered:**
- [P1] Stream Audio
- [P1] Visual Feedback
- [P1] Restrict Play Count

## 1. Refactor `AudioPlayerBar`
- Path: `lib/features/listening/presentation/widgets/listening/audio_player_bar.dart`
- Change to `StatefulWidget`.
- Constructor parameters: `final String? audioUrl; final int maxPlayCount;`
- Add `AudioPlayer _player = AudioPlayer();` in `State`.
- Call `_player.setUrl(widget.audioUrl!)` in `initState` (if url is not null).
- Handle `dispose()` to call `_player.dispose()`.

## 2. State & UI Updates
- Listen to `_player.playerStateStream`:
  - When `processingState == ProcessingState.completed`, increment local `int _playCount`.
  - Pause the player and seek to zero when completed.
- Build UI using `StreamBuilder` on `playerStateStream` and `positionDataStream`.
- Replace static icons with Play/Pause buttons.
- Disable Play button if `_playCount >= widget.maxPlayCount`.

## 3. Connect to Pages
- Pass `questionData?.assetCdnUrl` and `questionData?.maxPlayCount ?? 2` to `AudioPlayerBar` inside `ListeningMultipleChoicePage` and `ListeningMatchingPage`.
