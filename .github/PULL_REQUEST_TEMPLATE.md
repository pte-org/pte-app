## Summary

Mô tả ngắn PR này làm gì (1–2 câu).

## Type

- [ ] `feat:` — Tính năng mới
- [ ] `fix:` — Sửa bug
- [ ] `refactor:` — Cải thiện code (không thêm feature / không sửa bug)
- [ ] `chore:` — Config, dependency, CI
- [ ] `docs:` — Tài liệu

## Changes

- Liệt kê thay đổi chính
- Không cần liệt kê từng dòng (diff sẽ hiển thị)
- Highlight quyết định kiến trúc hoặc workaround quan trọng

## Closes / Related

Closes #<!-- issue number -->

## How to Test

Các bước để verify PR này hoạt động đúng.

---

## AI-Generated Code

- [ ] Một phần/toàn bộ code trong PR này được tạo bởi AI (Claude Code, Copilot, v.v.)
- [ ] Nếu có: đã review thủ công từng file, kiểm tra file size, hardcoded string, layer violation

---

## Code Review Checklist — Universal

- [ ] Commit messages theo Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`)
- [ ] Không debug code còn sót (`print()`, `debugPrint()` không cần thiết)
- [ ] PR size < 400 dòng diff (không tính generated code, lock file)
- [ ] Không có string hardcode trong widget (kiểm tra `lib/core/constants/app_strings.dart`)
- [ ] Không có file nào > 300 dòng code logic

## Code Review Checklist — pte-app (Flutter / Dart)

- [ ] Không hardcode string trong widget (`❌ Text('Exam not found')` → `✅ Text(AppStrings.examNotFound)`)
- [ ] Không hardcode color (`❌ Color(0xFF1E88E5)` → `✅ AppColors.primary`)
- [ ] File < 300 dòng (BLoC OK nếu đã split: `*_bloc.dart` / `*_event.dart` / `*_state.dart`)
- [ ] `State` có resource controller đã override `dispose()` (`TextEditingController`, `AnimationController`, `FocusNode`, `StreamSubscription`)
- [ ] Không dùng `BuildContext` sau `await` mà không kiểm tra `if (!mounted) return`
- [ ] Widget dùng ở 2+ feature đã được extract vào `lib/core/widgets/` (không copy-paste)
- [ ] BLoC events dùng `sealed class` (Dart 3 — type-safe, exhaustive)
- [ ] BLoC states là class riêng, immutable (không dùng boolean flag như `isLoading`, `hasError`)
- [ ] `build()` method < 50 dòng (extract sub-widget nếu hơn)
- [ ] Dùng `BlocSelector` thay vì `BlocBuilder` khi chỉ phụ thuộc vào 1 field của state

## Sign-off

- [ ] Đã đọc [Coding Standards App](../docs/CODING_STANDARDS_APP.md) trước khi submit
- [ ] Đã test PR trên thiết bị/emulator và verify behavior đúng
- [ ] Không có breaking change (hoặc đã giải thích tại sao cần thiết)
