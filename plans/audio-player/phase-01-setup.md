# Phase 1: Setup & Models

**Stories Covered:**
- [P1] Dependency Installation

## 1. Install `just_audio`
- Run `flutter pub add just_audio` in terminal.

## 2. Update `Question` Model
- Path: `lib/features/listening/data/models/question.dart`
- Add `final String? assetCdnUrl;`
- Add `final int? maxPlayCount;`
- Update constructor and `fromJson` factory method.
