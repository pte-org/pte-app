# Spec: Listening Audio Player Integration

**Date:** 2026-07-03
**Status:** Ready

---

## Problem Statement
The Listening test requires students to listen to audio passages. Currently, the `AudioPlayerBar` is a static visual placeholder. It needs to be upgraded to a fully functional streaming player using the `cdn_url` provided by the backend API, and it must enforce business rules like limiting the number of times a student can play the audio.

---

## User Stories

- **[P1]** As a student taking a listening test, I want to click play on the audio bar to stream the question's audio without lag.
  Accepted when: The `AudioPlayerBar` uses `just_audio` to play the `cdn_url` provided in the `Question` model.

- **[P1]** As a student, I want to see visual feedback (buffering, playing, progress bar) so I know the current status of the audio.
  Accepted when: The UI updates to reflect buffering and playback position.

- **[P1]** As the exam system, I want to restrict the student to play the audio a maximum of N times (e.g., `maxPlayCount` = 2) so that test integrity is maintained.
  Accepted when: The play button becomes disabled and cannot be triggered after the audio has played to completion the maximum allowed number of times.

---

## Functional Requirements

1. **FR-01 (Dependency):** Install and configure the `just_audio` package.
2. **FR-02 (Data Model):** Update the frontend `Question` model to include `String? assetCdnUrl` and `int maxPlayCount`.
3. **FR-03 (State Management):** Refactor `AudioPlayerBar` from `StatelessWidget` to `StatefulWidget`.
4. **FR-04 (Playback):** The widget must initialize a `AudioPlayer` instance and set the audio source to `assetCdnUrl`.
5. **FR-05 (Max Play Rule):** Maintain an internal `playCount` state. Increment it when the `processingState` of `just_audio` reaches `completed`.
6. **FR-06 (Disabling):** Disable the play button visually and functionally when `playCount >= maxPlayCount`.

---

## Non-Functional Requirements

- Performance: The audio must be streamed, not fully downloaded before playing.
- Resource Management: The `AudioPlayer` must be properly disposed of in the widget's `dispose()` method to prevent memory leaks and zombie background audio.

---

## Success Criteria

- [ ] `just_audio` is successfully added to `pubspec.yaml`.
- [ ] `AudioPlayerBar` plays a valid mock URL (e.g., an mp3 URL) when tapped.
- [ ] The play button locks out after 2 plays (using a mock `maxPlayCount: 2`).

---

## Out of Scope
- Actually hooking up the `GET /questions` API (the UI will continue using mock data containing the URL).
- Storing the `playCount` in a global state or remote database (local widget state is sufficient for now, though it means refreshing the page resets the count).

---

## Assumptions
- The backend guarantees that the `cdn_url` string is a direct link to a streamable audio file (e.g., MP3, AAC).
