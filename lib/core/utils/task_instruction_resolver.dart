import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';

/// The instruction a task screen shows, in priority order:
/// 1. [apiInstruction] — the admin-editable text the server sends with the task;
/// 2. [meta]'s built-in instruction, for older responses without one;
/// 3. [fallback] — when the app has no metadata for the task type.
///
/// Callers pass the [meta] they already resolved rather than a task-type key:
/// a custom task type only finds its metadata through its runtime renderer.
String resolveTaskInstruction({
  String? apiInstruction,
  TaskTypeMeta? meta,
  String fallback = AppStrings.defaultTaskInstruction,
}) {
  final fromApi = apiInstruction?.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return fromApi;
  }
  return meta?.instruction ?? fallback;
}
