# Phase 3 — Reading preview walkthrough (localhost:8080) + verify

**Covers:** P1 review nav, all R success criteria · **Depends on:** Phase 1 + 2 · **Testing:** gate

---

## Tasks

### 1. Reading preview (`lib/dev/reading_preview.dart`)
- Mirror `lib/dev/core_test_preview.dart`: a public `ReadingWalkthrough` (StatefulWidget) holding
  R1–R4 in an `IndexedStack`, each wired to `onNext`/`onBack` that move the index.
- Order: R1 (1) → R2 (2) → R3 (3) → R4 (4). First screen may keep Back hidden if desired.
- Runnable: `flutter run -t lib/dev/reading_preview.dart -d chrome --web-port=8080` — this is the
  **localhost:8080** preview that replaces the grammar one for this review.

### 2. Standards gate
- `flutter analyze lib test` → 0 issues.
- `flutter test` → green (existing + new reading widget tests).
- Files ≤ 300 lines; `build()` ≤ 50; no bare `Color(0x`, inline `Text` literals, or magic numbers.

### 3. Visual walkthrough
- Run the reading preview on `localhost:8080`; drive Next through R1→R2→R3→R4; screenshot each;
  compare to the reference screenshots. Exercise a drag on R2 and R3 and a resize on R4.

## Acceptance criteria (feature)

- [ ] R1–R4 render correctly via the preview; Next/Back walk the four screens.
- [ ] Drag works on R2 (reorder) and R3 (fill); R4 divider resizes.
- [ ] `flutter analyze` = 0; `flutter test` green.
- [ ] `main.dart`/`app.dart` unchanged (preview via `-t`).
