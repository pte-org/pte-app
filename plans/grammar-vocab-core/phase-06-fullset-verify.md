# Phase 6 — Verify full set + Next/Back walkthrough

**Covers:** all R2 success criteria · **Depends on:** Phase 4 + Phase 5
**Testing:** gate

---

## Tasks

### 1. Standards gate
- `flutter analyze lib test` → **0 issues**.
- `flutter test` → green (existing + new widget tests).
- Every new/edited file ≤ 300 lines; every `build()` ≤ 50; no bare `Color(0x`, no inline `Text`
  string literals, no magic numbers in the new widgets.
- Confirm Q30 added **no** new dropdown/grid code (grep: only `WordMatchingGrid` /
  `WordMatchPage` are reused).

### 2. Visual walkthrough (dev preview)
- Run `flutter run -t lib/dev/core_test_preview.dart -d chrome`.
- Drive Next through all 5 screens; screenshot each; compare to the reference screenshots:
  - Q1 radio · Q26 word-match (no `=`, no example) · Q27 definitions (left-aligned, wrapping) ·
    Q28 inline dropdowns · Q30 reduced/sentimental (collocation). Q29 is not built.
- Enter an answer on one screen, page away and back, confirm it persists.

## Acceptance criteria (Round 2)

- [ ] All 5 screens render matching their screenshots; Q26/Q30 have no example row and no `=`.
- [ ] Next/Back walk the full chain (Q1→Q26→Q27→Q28→Q30) with real numbers; answers persist.
- [ ] `flutter analyze` = 0; `flutter test` green.
- [ ] No production entrypoint (`main.dart`/`app.dart`) changed; navigation only in the dev preview.
