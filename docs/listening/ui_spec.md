# Listening UI Specification

**Module:** `features/listening`

## 1. Architectural Overview
The Aptis Listening test consists of 4 distinct parts. However, from a UI perspective, these 4 parts share only two primary structural patterns. To ensure a maintainable and dry codebase, the UI has been consolidated into **two reusable page templates**.

- **Part 1 & Part 3**: Handled by `ListeningMultipleChoicePage`.
- **Part 2 & Part 4**: Handled by `ListeningMatchingPage`.

Both pages are wrapped in the global `ExamScaffold` to maintain consistency across the app (timer, navigation, flags, etc.).

---

## 2. Page Templates

### 2.1. `ListeningMultipleChoicePage`
**Used for:** Part 1 (Single question, 3-4 options) & Part 3 (Multiple questions, 3-4 options).
**Path:** `lib/features/listening/presentation/pages/listening/listening_multiple_choice_page.dart`

**Features:**
- Accepts a dynamic list of questions.
- If a single question is provided (like Part 1), it renders normally below the audio bar.
- If multiple questions are provided (like Part 3), it automatically renders them in a scrollable list below the audio bar.
- Supports any number of options per question (typically 3 or 4) by mapping data to the `MultipleChoiceOption` widget.

### 2.2. `ListeningMatchingPage`
**Used for:** Part 2 (Short matching sentences) & Part 4 (Long opinion statements).
**Path:** `lib/features/listening/presentation/pages/listening/listening_matching_page.dart`

**Features:**
- Built to handle "Matching" type questions using dropdowns.
- Uses `DropdownMatchingList` to render a list of statements, each accompanied by a dropdown box for selecting the matching answer.
- Designed to be flexible with text length. It wraps the label text in an `Expanded` widget so that long sentences (like Part 4 opinions) wrap naturally to the next line without causing layout overflow, while the dropdown remains right-aligned.

---

## 3. Core Widgets

### 3.1. `AudioPlayerBar`
**Path:** `lib/features/listening/presentation/widgets/listening/audio_player_bar.dart`
- A static UI template representing the red audio playback bar.
- Uses `AppColors.accentRed` and stretches edge-to-edge across the screen.
- Currently a visual placeholder, ready to be integrated with an audio package (e.g., `just_audio` or `audioplayers`) when domain models are finalized.

### 3.2. `MultipleChoiceOption`
**Path:** `lib/features/listening/presentation/widgets/listening/multiple_choice_option.dart`
- A reusable component for rendering a single radio-button style option.
- Formats the option letter in bold (e.g., "**A.** 4.00 pm").
- Built using a custom circular container to exactly match the Aptis design system.

### 3.3. `DropdownMatchingList`
**Path:** `lib/features/listening/presentation/widgets/listening/dropdown_matching_list.dart`
- A reusable list component for rendering `Label + Dropdown` rows.
- Accepts a list of labels and a 2D list of options (for each dropdown).
- Triggers a callback `onChanged(index, value)` whenever a user selects an item from any dropdown in the list.

---

## 4. Technical Notes (Layout Constraints)
Because `ExamScaffold` provides an internal `SingleChildScrollView` by default (when `scrollableBody: true`), passing a `Column` containing an `Expanded` widget will result in an unbounded height exception (`RenderFlex` error). 

To resolve this, both `ListeningMultipleChoicePage` and `ListeningMatchingPage` explicitly pass `scrollableBody: false` to `ExamScaffold`. This disables the outer scroll view, allowing the individual Listening pages to manage their own internal `SingleChildScrollView` perfectly.

## 5. Question Types Overview
- part 1: In the first section, you need to identify specific information such as a phone number, a time, or a place by listening to a short message or a dialogue. 
- part 2:  In the next section, you will listen to short monologues by four people on a certain topic. You need to match each speaker to a piece of information.
- part 3: In the third section, you will listen to two monologues on different topics. For each monologue, you need to answer two questions about the opinion of the speaker on certain aspects of the topic.
- part 4:  In the fourth and final section, you'll listen to a man and a woman discuss a topic and express certain opinions about it. Your task is to identify who expresses which opinion.