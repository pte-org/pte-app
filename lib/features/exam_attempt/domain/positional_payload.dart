/// Positional comma-join used by both fill-blank task types: one entry per
/// gap in gap-index order, an empty entry (including a required trailing
/// one) for every unfilled gap — so backend positional parsing never
/// misaligns (shared by `FILL_IN_THE_BLANKS_DRAG_AND_DROP`'s and
/// `FILL_IN_THE_BLANKS_DROPDOWN`'s cubits; `null` entries become `''`).
String positionalPayload(List<String?> values) {
  return values.map((value) => value ?? '').join(',');
}
