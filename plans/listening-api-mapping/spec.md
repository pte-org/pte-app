# Spec: Listening API Data Mapping

**Date:** 2026-07-03
**Status:** Ready

---

## Problem Statement
The Listening Module UI needs to integrate with the backend's V4 Flat Question Model. The backend returns a single flat `Question` object (with a string `content` and flat arrays for `options`/`correctAnswers`), but the UI templates (`ListeningMultipleChoicePage` and `ListeningMatchingPage`) require structured data like explicit labels and dropdown option clusters.

---

## User Stories

- **[P1]** As a student taking the Listening test, I want to see the Multiple Choice questions (Parts 1 & 3) rendered correctly with their respective options so that I can select my answer.
  Accepted when: The UI successfully maps the `content` and `options` array from the API to the `ListeningMultipleChoicePage` widget.

- **[P1]** As a student taking the Listening test, I want to see the Matching questions (Parts 2 & 4) rendered correctly with labels and dropdowns so that I can select the correct match.
  Accepted when: The UI successfully parses `[Blank X]` tags from the `content` field to generate labels, and maps the `options` array to the dropdowns in the `ListeningMatchingPage` widget.

---

## Functional Requirements

1. **FR-01 (Routing):** The system must route the Question data to `ListeningMultipleChoicePage` if `part == 1` or `part == 3`.
2. **FR-02 (Routing):** The system must route the Question data to `ListeningMatchingPage` if `part == 2` or `part == 4`.
3. **FR-03 (Multiple Choice Parsing):** For Multiple Choice, the system maps the `content` directly as the question text, and the `options` array directly as the radio button choices.
4. **FR-04 (Matching Parsing):** For Matching, the system must parse the `content` string using Regex to identify `[Blank X]` tags. The text immediately preceding the tag becomes the label (e.g., "Speaker A wants to").
5. **FR-05 (Option Chunking):** For Matching, the system must chunk the flat `options` array into sub-arrays for each dropdown, based on the number of blanks found.

---

## Non-Functional Requirements

- Performance: Regex parsing of the `content` string must occur within < 50ms to prevent UI frame drops.

---

## Success Criteria

- [ ] A mapper utility (e.g., `ListeningQuestionMapper`) is implemented and unit tested for parsing `[Blank X]`.
- [ ] Both Listening pages render successfully using real or mocked API JSON data conforming to the V4 spec.

---

## Out of Scope
- Fetching the actual API over HTTP (this spec covers the data mapping and parsing layer only).
- State management for saving the user's answers back to the API.

---

## Assumptions
- The backend guarantees that the `options` array length is exactly a multiple of the number of `[Blank X]` tags in the content for Matching questions.
