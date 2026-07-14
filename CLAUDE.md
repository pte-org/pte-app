@docs/CODING_STANDARDS_APP.md

# aptis-app — AI Code Generation Rules

## Feature Structure

New features go in: `lib/features/{name}/{data,domain,presentation}/`

Shared widgets: `lib/core/widgets/` — extract here if a widget is used in 2+ features.

Constants: `lib/core/constants/app_strings.dart`, `app_colors.dart`, `app_dimensions.dart`

## Critical Rules (enforce on every file you write)

1. **No hardcoded strings** — use `AppStrings.*` in every `Text()` widget
2. **No hardcoded colors** — use `AppColors.*` (never `Color(0xFF...)`)
3. **File ≤ 300 lines** — split BLoC: `*_bloc.dart` / `*_event.dart` / `*_state.dart`
4. **dispose() all controllers** — override `dispose()` for every `TextEditingController`, `AnimationController`, `FocusNode`, `StreamSubscription`
5. **mounted check after await** — always `if (!mounted) return;` before using BuildContext after any await
6. **BLoC events = sealed class** (Dart 3) — type-safe, exhaustive switch
7. **BLoC states = immutable classes** — no boolean flags (`isLoading`, `hasError`) on a single state class
8. **build() ≤ 50 lines** — extract sub-widgets as private `_WidgetName` classes in same file or separate file
9. **BlocSelector over BlocBuilder** — when component depends on only one field of the state
10. **No secrets in source** — API keys, OAuth tokens via flutter_dotenv or compile-time env injection

## File Size Rule — Auto-Generated Code

**Exempt from 300-line limit**: Drift-generated `.g.dart`, Freezed `.freezed.dart`, JSON codegen `.g.dart`, build artifacts.

**NOT exempt**: AI-generated code (Claude Code, Copilot, Cursor) — split if over 300 lines.

## Dart Version

Minimum SDK: Dart 3.x — sealed classes are fully supported. Do NOT use abstract class workarounds for BLoC events.

## When Updating Coding Standards

Any PR that modifies `docs/CODING_STANDARDS_APP.md` **must** also update this `CLAUDE.md` in the same PR.
