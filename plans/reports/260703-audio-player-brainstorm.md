# Brainstorm Report: Listening Audio Player Integration
**Date:** 2026-07-03
**Topic:** How to fetch, play, and manage state for Listening test audio files, adhering to the Asset entity architecture (`audio_listening` type).

## What we explored
- The API architecture distinguishes between `storage_key` and `cdn_url`. Listening audio is a public asset, so it will have a publicly accessible `cdn_url` via a CDN.
- We analyzed how the Frontend will obtain this URL and which package to use for streaming audio.
- We discussed the business logic constraint of `maxPlayCount`.

## Decisions Made
1. **Data Fetching (Option A):** The backend API will hydrate the `Question` response with the `Asset` data (specifically the `cdn_url`). The frontend will not need to make secondary requests to the `/assets` endpoint to resolve IDs.
2. **Player Package:** We selected `just_audio` as the official streaming package due to its robust handling of network states (buffering, playing, etc.).
3. **Play Count Enforcement:** The `AudioPlayerBar` will listen to the playback state. When the audio finishes playing, it will increment a counter. If the counter reaches `maxPlayCount`, the UI will disable the play button and prevent further playback.

## What’s Next
- Proceed with `/ck-plan` or `/ck-cook` to install `just_audio`, update the `Question` model to include `assetCdnUrl` and `maxPlayCount`, and implement the stateful logic inside `AudioPlayerBar`.
