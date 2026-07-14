# Quy Tắc Viết Mã Aptis App (Flutter / Dart)

**Ngày cập nhật:** 2026-06-24  
**Đối tượng:** Nhóm phát triển Flutter/Dart, Mobile Team  
**Phiên bản:** 1.0

---

## Mục Lục

1. [Nguyên Tắc Cốt Lõi](#nguyên-tắc-cốt-lõi)
2. [Quy Tắc Đặt Tên](#quy-tắc-đặt-tên)
3. [Cấu Trúc File và Thư Mục](#cấu-trúc-file-và-thư-mục)
4. [Nguyên Tắc SOLID trong Flutter/BLoC](#nguyên-tắc-solid-trong-flutterbloc)
5. [Phân Rã Widget (Widget Decomposition)](#phân-rã-widget-widget-decomposition)
6. [Quản Lý Hằng Số (Constants Management)](#quản-lý-hằng-số-constants-management)
7. [Pattern BLoC](#pattern-bloc)
8. [Vòng Đời Tài Nguyên (Resource Lifecycle)](#vòng-đời-tài-nguyên-resource-lifecycle)
9. [An Toàn Bất Đồng Bộ (Async Safety)](#an-toàn-bất-đồng-bộ-async-safety)
10. [Tối Ưu Hóa Hiệu Suất](#tối-ưu-hóa-hiệu-suất)
11. [Những Lỗi Phổ Biến](#những-lỗi-phổ-biến)
12. [Danh Sách Kiểm Tra Code Review](#danh-sách-kiểm-tra-code-review)

---

## Nguyên Tắc Cốt Lõi

Aptis App tuân thủ các nguyên tắc toàn đội (áp dụng cho cả aptis-api, aptis-app, aptis-web):

### Nhóm 1 — Nguyên Tắc Thiết Kế (Beyond SOLID)

| Nguyên Tắc | Quy Tắc |
|---|---|
| **DRY** (Don't Repeat Yourself) | Code xuất hiện ở 3 nơi → **bắt buộc extract** thành function/widget/utility. Không "để sau refactor". |
| **KISS** (Keep It Simple) | 2 cách giải quyết → chọn **cách đơn giản** hơn. Kể cả khi cách phức tạp nghe "cool" hơn. |
| **YAGNI** (You Aren't Gonna Need It) | **Không code feature, parameter, layer** "đề phòng tương lai" khi chưa có yêu cầu cụ thể. |
| **Fail Fast** | **Validate đầu vào ngay** tại boundary (widget input), không để lỗi lan sâu vào domain logic. |
| **Law of Demeter** | Không chain quá 2 cấp: `a.getB().doSomething()` ✓ — `a.getB().getC().getD().do()` ✗ |
| **CQS** (Command-Query Separation) | Method **hoặc** trả về giá trị **HOẶC** thay đổi state, không làm cả hai. |

### Nhóm 2 — Clean Code Rules

- **Tên tự giải thích:** Không viết tắt (`usr`, `cnt`, `tmp`). Tên phải dễ hiểu.
- **Function làm 1 việc:** Nếu tên chứa "và" → **tách thành 2 hàm**.
- **Comment giải thích WHY, không WHAT:** Code đã nói WHAT rồi. Comment chỉ cho constraint ẩn/workaround.
- **Không dead code:** Không comment-out code — xóa đi, Git lưu lịch sử.
- **Không magic number/string:** Mọi giá trị có nghĩa phải có tên.

### Nhóm 3 — Team / Process Rules

- **Boy Scout Rule:** Mỗi lần sửa file, để lại sạch hơn.
- **PR size limit:** Max **400 dòng thay đổi** (diff). Nếu lớn hơn → tách PR.
- **Conventional Commits:** `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`
- **No Broken Windows:** Thấy bug nhỏ → tạo issue ngay hoặc fix luôn nếu <15 phút.
- **AI-generated code review:** Code do AI sinh phải được review như code người.

---

## Quy Tắc Đặt Tên

### File: `snake_case.dart`

Tất cả file Dart sử dụng **snake_case** với tiền tố rõ ràng chỉ type của file.

**✓ Đúng:**

```dart
// BLoC events
exam_started_event.dart
submit_answer_event.dart

// BLoC state
exam_loading_state.dart
exam_ready_state.dart
exam_error_state.dart

// BLoC itself
exam_attempt_bloc.dart

// Widgets
exam_card_widget.dart
exam_timer_widget.dart
answer_option_card.dart

// Repositories
exam_repository_impl.dart
student_repository_impl.dart

// Models
exam_response_model.dart
question_model.dart
```

**✗ Sai:**

```dart
ExamStartedEvent.dart      // ❌ PascalCase không được dùng cho file
exam_started_event_class.dart  // ❌ Thêm "_class" dư thừa
ExamAttempt.dart           // ❌ Tên không rõ type
```

### Class: `PascalCase`

Tất cả class sử dụng **PascalCase**, bao gồm BLoC, State, Event, Widget.

**✓ Đúng:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> { }
class ExamStartedEvent extends ExamEvent { }
class ExamLoadingState extends ExamState { }
class ExamCardWidget extends StatelessWidget { }
class ExamRepository { }  // Abstract
class ExamRepositoryImpl extends ExamRepository { }
```

**✗ Sai:**

```dart
class exam_attempt_bloc { }        // ❌ snake_case cho class
class Exam_Started_Event { }       // ❌ Mixed case
class examCardWidget { }           // ❌ camelCase cho class
```

### Method & Variable: `camelCase`

Tất cả method, variable sử dụng **camelCase**, bắt đầu bằng chữ cái thường.

**✓ Đúng:**

```dart
Future<void> loadExamDetails() { }
void submitAnswer(String answerId) { }
int studentId = 42;
String examTitle = 'Math Quiz';
bool isLoading = false;
```

**✗ Sai:**

```dart
Future<void> LoadExamDetails() { }    // ❌ PascalCase
void submit_answer() { }              // ❌ snake_case
int StudentId = 42;                   // ❌ PascalCase
String _examTitle = 'Math Quiz';      // ❌ Private khi không cần
```

### Constant: `lowerCamelCase const`

Tất cả constant sử dụng **lowerCamelCase**, không dùng UPPER_SNAKE_CASE (Java style không dùng trong Dart).

**✓ Đúng:**

```dart
const String examNotFound = 'Exam not found';
const String studentAlreadyEnrolled = 'You are already enrolled';
const Duration retryDelay = Duration(seconds: 3);
const int maxAttempts = 5;
const double passingScore = 50.0;
```

**✗ Sai:**

```dart
const String EXAM_NOT_FOUND = 'Exam not found';      // ❌ Java style
const String examNotFound = 'Exam not found';        // ✓ Nhưng nếu không const là sai
String examNotFound = 'Exam not found';              // ❌ Thiếu const
const examNotFound = 'Exam not found';               // ❌ Thiếu type
```

### Private Member: `_prefix`

Các member private (field, method) dùng **underscore prefix** và **camelCase**.

**✓ Đúng:**

```dart
class ExamCard extends StatelessWidget {
  final ExamRepository _examRepository;
  
  const ExamCard({required ExamRepository examRepository})
    : _examRepository = examRepository;
  
  void _loadExamDetails() { }
  Future<void> _submitAnswer(String id) { }
}
```

**✗ Sai:**

```dart
class ExamCard extends StatelessWidget {
  final ExamRepository examRepository;  // ❌ Public field
  
  void loadExamDetails() { }            // ❌ Public khi nên private
  Future<void> _SubmitAnswer() { }      // ❌ PascalCase sau _
}
```

### Anti-Pattern: Naming Violations Table

| ❌ Don't | ✅ Do | Lý Do |
|---|---|---|
| `cnt`, `usr`, `tmp`, `idx` | `attemptCount`, `userId`, `tempData`, `itemIndex` | Tên đầy đủ tự giải thích |
| `proc()`, `calc()`, `do_stuff()` | `processSubmittedAnswer()`, `calculateTotalScore()`, `updateExamStatus()` | Hàm phải nói rõ mục đích |
| `ExamBloc.dart` | `exam_attempt_bloc.dart` | File dùng snake_case |
| `class examCard { }` | `class ExamCard { }` | Class dùng PascalCase |
| `int x = 1000` | `const int maxRetryAttempts = 1000` | Magic number phải có tên |
| `final _exam` | `final _examRepository` | Tên private phải rõ nghĩa |

---

## Cấu Trúc File và Thư Mục

### Cấu Trúc Feature (Feature-First)

Aptis App sử dụng **cấu trúc feature-first** với Clean Architecture (Data → Domain → Presentation).

```
features/{feature_name}/
├── data/
│   ├── models/
│   │   └── exam_response_model.dart         # ← JSON DTO, fromJson/toJson
│   └── repositories/
│       └── exam_repository_impl.dart        # ← Implements ExamRepository
├── domain/
│   ├── entities/
│   │   └── exam.dart                        # ← Pure Dart, no Flutter import
│   ├── repositories/
│   │   └── exam_repository.dart             # ← Abstract interface
│   └── usecases/
│       └── start_exam_usecase.dart          # ← Optional, 1 use case = 1 class
├── presentation/
│   ├── bloc/
│   │   ├── exam_bloc.dart                   # ← BLoC logic
│   │   ├── exam_event.dart                  # ← Events (sealed class)
│   │   └── exam_state.dart                  # ← States (separate classes)
│   ├── pages/
│   │   └── exam_page.dart                   # ← 1 file = 1 full-screen page
│   └── widgets/
│       ├── exam_card.dart
│       ├── question_display.dart
│       └── answer_option.dart
└── exam_module.dart                         # ← GetIt registration
```

### Mục Đích Mỗi Thư Mục

| Folder | Mục Đích | Ghi Chú |
|---|---|---|
| `data/models/` | JSON DTO (từ API), `fromJson()`, `toJson()` | Không chứa business logic |
| `data/repositories/` | Triển khai abstract repository, gọi API | Chứa `ExamRepositoryImpl` |
| `domain/entities/` | Pure Dart objects, không import Flutter | Chứa `Exam` (entity, khác model) |
| `domain/repositories/` | Abstract class, interface cho data layer | `abstract class ExamRepository` |
| `domain/usecases/` | Optional; 1 use case = 1 class (thay vì feature service) | Ví dụ: `StartExamUseCase` |
| `presentation/bloc/` | BLoC, Event, State (3 file riêng) | Xử lý business logic của UI |
| `presentation/pages/` | Full-screen widget, 1 file = 1 page | Ví dụ: `ExamPage`, `ResultPage` |
| `presentation/widgets/` | Sub-widgets, reusable chỉ trong feature này | Nếu dùng 2+ feature → `core/widgets/` |

### Shared/Core Code

**`lib/core/`** chứa code dùng được bởi 2+ feature:

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_strings.dart           # ← User-facing messages, labels
│   │   ├── app_colors.dart            # ← Color palette
│   │   └── app_dimensions.dart        # ← Spacing, border radius, font size
│   ├── widgets/
│   │   ├── custom_button.dart         # ← Dùng ở 2+ feature
│   │   ├── error_dialog.dart
│   │   └── loading_spinner.dart
│   ├── exceptions/
│   │   ├── app_exception.dart         # ← Custom exception hierarchy
│   │   └── network_exception.dart
│   ├── extensions/
│   │   └── string_extension.dart      # ← Extension methods
│   └── utils/
│       └── logger.dart
├── features/
│   └── ...
└── main.dart
```

### File Size Limit

- **Max 300 dòng per file** (tính logic, không tính comments/imports)
- **BLoC exception:** Có thể split thành 3 file (bloc/event/state), mỗi file <150 dòng
- **Auto-generated code:** Miễn quy tắc 300 dòng (Freezed, json_serializable output)

**✓ Đúng:**

```dart
// exam_bloc.dart: 80 dòng
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> { }

// exam_event.dart: 60 dòng
sealed class ExamEvent {}
class ExamStartedEvent extends ExamEvent { }
class ExamAnswerSubmittedEvent extends ExamEvent { }

// exam_state.dart: 70 dòng
abstract class ExamState {}
class ExamLoadingState extends ExamState { }
class ExamReadyState extends ExamState { final Exam exam; }
```

**✗ Sai:**

```dart
// exam_page.dart: 450 dòng (chứa page + widgets + BLoC logic)
class ExamPage extends StatelessWidget {
  // ... 150 dòng UI
  // ... 150 dòng BLoC event definitions
  // ... 150 dòng helper methods
}
```

### GetIt Dependency Injection

Mỗi feature phải có `{feature}_module.dart` đăng ký tất cả repository và BLoC.

**`features/exam/exam_module.dart`:**

```dart
import 'package:get_it/get_it.dart';
import 'data/repositories/exam_repository_impl.dart';
import 'domain/repositories/exam_repository.dart';
import 'presentation/bloc/exam_bloc.dart';

final getIt = GetIt.instance;

void setupExamModule() {
  // Register repository
  getIt.registerSingleton<ExamRepository>(
    ExamRepositoryImpl(apiClient: getIt()),
  );
  
  // Register BLoC
  getIt.registerSingleton<ExamAttemptBloc>(
    ExamAttemptBloc(repository: getIt()),
  );
}
```

**`main.dart`:**

```dart
void main() async {
  // Setup all modules
  setupExamModule();
  setupResultModule();
  // ...
  
  runApp(const AptisApp());
}
```

---

## Nguyên Tắc SOLID trong Flutter/BLoC

### S — Single Responsibility

Mỗi BLoC xử lý **1 feature flow**, mỗi widget có **1 UI concern**.

**✓ Đúng:**

```dart
// ✓ Tách rõ: ExamBloc xử lý tải đề, không xử lý submit kết quả
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  Future<void> _onExamStarted(ExamStartedEvent event, Emitter emit) async {
    emit(ExamLoadingState());
    try {
      final exam = await _repository.fetchExam(event.examId);
      emit(ExamReadyState(exam: exam));
    } catch (e) {
      emit(ExamErrorState(message: e.toString()));
    }
  }
}

class ExamResultBloc extends Bloc<ExamResultEvent, ExamResultState> {
  // ✓ Riêng BLoC cho submit kết quả
  Future<void> _onResultSubmitted(ResultSubmittedEvent event, Emitter emit) async {
    // ...
  }
}
```

**✗ Sai:**

```dart
// ❌ God BLoC: xử lý cả tải đề, submit kết quả, lưu progress
class ExamAndResultBloc extends Bloc<ExamEvent, ExamState> {
  Future<void> _onExamStarted(ExamStartedEvent event, Emitter emit) async { }
  Future<void> _onAnswerSubmitted(AnswerSubmittedEvent event, Emitter emit) async { }
  Future<void> _onResultSubmitted(ResultSubmittedEvent event, Emitter emit) async { }
  Future<void> _onProgressSaved(ProgressSavedEvent event, Emitter emit) async { }
}
```

### O — Open/Closed Principle

Repository luôn là **abstract interface**, BLoC nhận qua constructor, không hardcode `Impl`.

**✓ Đúng:**

```dart
abstract class ExamRepository {
  Future<Exam> fetchExam(String examId);
  Future<void> submitAnswer(String answerId, String response);
}

class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository _repository;  // ← Injected, abstract
  
  ExamAttemptBloc({required ExamRepository repository})
    : _repository = repository;
}

// main.dart
setupExamModule() {
  getIt.registerSingleton<ExamRepository>(
    ExamRepositoryImpl(apiClient: getIt()),  // ← Impl hidden
  );
}
```

**✗ Sai:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  late final ExamRepositoryImpl _repository;  // ❌ Concrete class
  
  ExamAttemptBloc() {
    _repository = ExamRepositoryImpl();  // ❌ Hardcoded
  }
}
```

### L — Liskov Substitution Principle

Subclass widget phải maintain parent contract, không có surprise behavior.

**✓ Đúng:**

```dart
abstract class BaseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const BaseButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(child: buildButtonContent(context)),
    );
  }
  
  Widget buildButtonContent(BuildContext context);
}

class PrimaryButton extends BaseButton {
  // ✓ Maintain callback semantics
  @override
  Widget buildButtonContent(BuildContext context) {
    return Text('Submit');
  }
}
```

**✗ Sai:**

```dart
class PrimaryButton extends BaseButton {
  @override
  Widget build(BuildContext context) {
    // ❌ Callback diabuse: onPressed được gọi x2
    return GestureDetector(
      onTap: () {
        onPressed();
        onPressed();  // Surprise behavior
      },
      child: Text('Submit'),
    );
  }
}
```

### I — Interface Segregation

Abstract repository chỉ khai báo method **cần thiết** cho feature đó, không bloated interface.

**✓ Đúng:**

```dart
abstract class ExamQueryRepository {
  Future<Exam> fetchExam(String examId);
  Future<List<Question>> fetchQuestions(String examId);
}

abstract class ExamCommandRepository {
  Future<void> submitAnswer(String answerId, String response);
  Future<void> completeExam(String examId, SubmitExamRequest request);
}

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final ExamQueryRepository _queryRepo;  // ← Focused
  ExamBloc({required ExamQueryRepository queryRepo})
    : _queryRepo = queryRepo;
}

class ExamResultBloc extends Bloc<ExamResultEvent, ExamResultState> {
  final ExamCommandRepository _commandRepo;  // ← Focused
  ExamResultBloc({required ExamCommandRepository commandRepo})
    : _commandRepo = commandRepo;
}
```

**✗ Sai:**

```dart
abstract class ExamRepository {
  // ❌ 20 methods không liên quan
  Future<Exam> fetchExam(String examId);
  Future<void> submitAnswer(String answerId, String response);
  Future<void> completeExam(String examId, SubmitExamRequest request);
  Future<List<Student>> getAllStudents();  // ← Không liên quan
  Future<User> getCurrentUser();           // ← Không liên quan
  Future<void> deleteExam(String examId);  // ← Không dùng trong exam taking
}
```

### D — Dependency Inversion

BLoC nhận dependency qua **constructor**, không `new` trực tiếp, không static.

**✓ Đúng:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository _examRepository;
  final StudentRepository _studentRepository;
  
  ExamAttemptBloc({
    required ExamRepository examRepository,
    required StudentRepository studentRepository,
  })  : _examRepository = examRepository,
        _studentRepository = studentRepository;
}

// Setup in module
getIt.registerSingleton<ExamAttemptBloc>(
  ExamAttemptBloc(
    examRepository: getIt(),
    studentRepository: getIt(),
  ),
);
```

**✗ Sai:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  late final ExamRepository _examRepository;
  
  ExamAttemptBloc() {
    _examRepository = ExamRepositoryImpl();  // ❌ Hardcoded
  }
}

// Static không được
class ExamService {
  static final _repository = ExamRepositoryImpl();  // ❌
}
```

---

## Phân Rã Widget (Widget Decomposition)

### Rule 1: `build()` < 50 dòng

Widget `build()` method phải < 50 dòng code. Nếu vượt, **extract sub-widget**.

**✓ Đúng:**

```dart
class ExamCard extends StatelessWidget {
  final Exam exam;
  
  const ExamCard({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _ExamHeader(exam: exam),          // ← Extract
          _ExamBody(exam: exam),            // ← Extract
          _ExamFooter(exam: exam),          // ← Extract
        ],
      ),
    );
  }
}

// Sub-widget (riêng file hoặc cùng file nếu <30 dòng)
class _ExamHeader extends StatelessWidget {
  final Exam exam;
  const _ExamHeader({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(exam.title, style: Theme.of(context).textTheme.headline6),
    );
  }
}

class _ExamBody extends StatelessWidget {
  final Exam exam;
  const _ExamBody({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(exam.description),
    );
  }
}

class _ExamFooter extends StatelessWidget {
  final Exam exam;
  const _ExamFooter({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () { },
        child: const Text('Start Exam'),
      ),
    );
  }
}
```

**✗ Sai:**

```dart
class ExamCard extends StatelessWidget {
  final Exam exam;
  
  const ExamCard({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    // ❌ 80 dòng của Column/Row/Text
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(exam.title, style: Theme.of(context).textTheme.headline6),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(exam.description),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${exam.questionCount} questions'),
                Text('${exam.durationMinutes} min'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () { },
              child: const Text('Start Exam'),
            ),
          ),
          // ... more widgets
        ],
      ),
    );
  }
}
```

### Rule 2: Widget class < 200 dòng

Widget class (tính cả `build()`, properties, helpers) phải < 200 dòng. Nếu vượt, **tách thành file riêng**.

**✓ Đúng:**

```dart
// exam_card.dart (60 dòng)
class ExamCard extends StatelessWidget {
  final Exam exam;
  const ExamCard({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Card(child: _ExamHeader(exam: exam));
  }
}

// exam_card_actions.dart (50 dòng)
class ExamCardActions extends StatelessWidget {
  final Exam exam;
  const ExamCardActions({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Row(children: [/* buttons */]);
  }
}

// exam_card_content.dart (50 dòng)
class ExamCardContent extends StatelessWidget {
  final Exam exam;
  const ExamCardContent({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Column(children: [/* content */]);
  }
}
```

**✗ Sai:**

```dart
// exam_card_widget.dart (300 dòng ❌)
class ExamCardWidget extends StatelessWidget {
  final Exam exam;
  
  const ExamCardWidget({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      // 50 dòng header
      child: Column(
        children: [
          // 50 dòng content
          Padding(...),
          // 50 dòng actions
          Row(...),
        ],
      ),
    );
  }
  
  // 60 dòng helper methods
  void _handleStartExam() { }
  void _handleSaveProgress() { }
  // ... more
}
```

### Rule 3: Const Constructor

Stateless widget hoặc immutable widget **phải dùng `const`** constructor.

**✓ Đúng:**

```dart
class ExamCard extends StatelessWidget {
  final Exam exam;
  
  const ExamCard({required this.exam});  // ← const
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Card(),  // ← const child
    );
  }
}

// Usage
const examCard = ExamCard(exam: exam);  // ← const
```

**✗ Sai:**

```dart
class ExamCard extends StatelessWidget {
  final Exam exam;
  
  ExamCard({required this.exam});  // ❌ Missing const
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Card(),  // ❌ Missing const
    );
  }
}

// Usage
var examCard = ExamCard(exam: exam);  // ❌ Should be const
```

### Rule 4: Stateless vs Stateful Decision

**Quy tắc:** Nếu widget **không cần mutable state** (TextEditingController, animation) → **dùng Stateless**.

**✓ Đúng:**

```dart
// ✓ Không cần state → Stateless
class ExamInfoCard extends StatelessWidget {
  final Exam exam;
  const ExamInfoCard({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(exam.title),
          Text(exam.description),
        ],
      ),
    );
  }
}

// ✓ Cần animate → Stateful
class ExamTimer extends StatefulWidget {
  final int durationSeconds;
  const ExamTimer({required this.durationSeconds});
  
  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('Time left');
  }
}
```

**✗ Sai:**

```dart
// ❌ Không cần state nhưng dùng Stateful
class ExamInfoCard extends StatefulWidget {
  final Exam exam;
  const ExamInfoCard({required this.exam});
  
  @override
  State<ExamInfoCard> createState() => _ExamInfoCardState();
}

class _ExamInfoCardState extends State<ExamInfoCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(widget.exam.title),
          Text(widget.exam.description),
        ],
      ),
    );
  }
}
```

---

## Quản Lý Hằng Số (Constants Management)

### Strings: `lib/core/constants/app_strings.dart`

Tất cả **user-facing messages, labels, error text** phải nằm trong `AppStrings`, không hardcode trong widget.

**`lib/core/constants/app_strings.dart`:**

```dart
class AppStrings {
  // Exam messages
  static const String examNotFound = 'Exam not found';
  static const String examStarting = 'Starting exam...';
  static const String examCompleted = 'Exam completed';
  
  // Error messages
  static const String errorLoadingExam = 'Failed to load exam';
  static const String errorSubmittingAnswer = 'Failed to submit answer';
  static const String errorNetwork = 'Network error. Please check your connection.';
  
  // Button labels
  static const String buttonStart = 'Start';
  static const String buttonSubmit = 'Submit';
  static const String buttonCancel = 'Cancel';
  
  // Validation
  static const String validationRequired = 'This field is required';
  static const String validationMinLength = 'Must be at least %d characters';
  
  // Enrollment
  static const String studentAlreadyEnrolled = 'You are already enrolled';
  static const String enrollmentSuccess = 'Enrolled successfully';
}
```

**✓ Đúng:**

```dart
// ✓ Use AppStrings constant
@override
Widget build(BuildContext context) {
  return BlocBuilder<ExamBloc, ExamState>(
    builder: (context, state) {
      return switch(state) {
        ExamLoadingState _ => Text(AppStrings.examStarting),
        ExamReadyState _ => Text(AppStrings.examCompleted),
        ExamErrorState s => Text(AppStrings.errorLoadingExam),
      };
    },
  );
}
```

**✗ Sai:**

```dart
// ❌ Hardcoded string
@override
Widget build(BuildContext context) {
  return BlocBuilder<ExamBloc, ExamState>(
    builder: (context, state) {
      return switch(state) {
        ExamLoadingState _ => Text('Starting exam...'),
        ExamReadyState _ => Text('Exam completed'),
        ExamErrorState s => Text('Failed to load exam'),
      };
    },
  );
}
```

### Colors: `lib/core/constants/app_colors.dart`

Không hardcode `Color(0xFF...)`. Dùng **AppColors constant hoặc Theme.of(context)**.

**`lib/core/constants/app_colors.dart`:**

```dart
class AppColors {
  // Primary palette
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Semantic colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);
  
  // Neutral
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerGrey = Color(0xFFBDBDBD);
}
```

**✓ Đúng:**

```dart
// ✓ Use AppColors
Container(
  color: AppColors.primaryBlue,
  child: Text(
    'Submit',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// ✓ Use Theme
Container(
  color: Theme.of(context).primaryColor,
  child: Text('Submit'),
)
```

**✗ Sai:**

```dart
// ❌ Hardcoded Color
Container(
  color: Color(0xFF1E88E5),  // Magic hex
  child: Text(
    'Submit',
    style: TextStyle(color: Color(0xFF212121)),
  ),
)
```

### Dimensions: `lib/core/constants/app_dimensions.dart`

Spacing, border radius, font size cùng nằm trong hằng số.

**`lib/core/constants/app_dimensions.dart`:**

```dart
class AppDimensions {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXl = 32.0;
  
  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  
  // Font sizes (hoặc dùng Theme.of(context).textTheme)
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeLarge = 16.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}
```

**✓ Đúng:**

```dart
Padding(
  padding: const EdgeInsets.all(AppDimensions.spacingMedium),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
    ),
    child: Text(
      'Exam Title',
      style: TextStyle(fontSize: AppDimensions.fontSizeLarge),
    ),
  ),
)
```

**✗ Sai:**

```dart
Padding(
  padding: const EdgeInsets.all(16),  // ❌ Magic number
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),  // ❌ Magic number
    ),
    child: Text(
      'Exam Title',
      style: TextStyle(fontSize: 16),  // ❌ Magic number
    ),
  ),
)
```

---

## Pattern BLoC

### Events: Sealed Class (Dart 3 syntax)

**Tất cả BLoC events phải dùng `sealed class`** cho type safety và exhaustive pattern matching.

**`presentation/bloc/exam_event.dart`:**

```dart
sealed class ExamEvent {}

class ExamStartedEvent extends ExamEvent {
  final String examId;
  ExamStartedEvent({required this.examId});
}

class ExamAnswerSubmittedEvent extends ExamEvent {
  final String questionId;
  final String response;
  
  ExamAnswerSubmittedEvent({
    required this.questionId,
    required this.response,
  });
}

class ExamTimerTickedEvent extends ExamEvent {
  final int secondsRemaining;
  ExamTimerTickedEvent({required this.secondsRemaining});
}

class ExamCompletedEvent extends ExamEvent {}
```

**✓ Đúng:**

```dart
sealed class ExamEvent {}

class ExamStartedEvent extends ExamEvent {
  final String examId;
  ExamStartedEvent({required this.examId});
}

// Type-safe dispatch
context.read<ExamBloc>().add(
  ExamStartedEvent(examId: '123'),  // ← Compiler ensures correct type
);
```

**✗ Sai:**

```dart
// ❌ Using abstract class (loses type safety)
abstract class ExamEvent {}

class ExamStartedEvent extends ExamEvent {
  final String examId;
  ExamStartedEvent({required this.examId});
}

// ❌ Using enum (not flexible for complex data)
enum ExamEventType { started, answered, timerTicked, completed }
class ExamEvent {
  final ExamEventType type;
  final dynamic data;  // ❌ Type-unsafe
}
```

### States: Separate Immutable Classes (NOT Boolean Flags)

**Mỗi state là class riêng**, không dùng boolean flag (`isLoading`, `hasError`).

**`presentation/bloc/exam_state.dart`:**

```dart
abstract class ExamState {}

class ExamInitialState extends ExamState {}

class ExamLoadingState extends ExamState {}

class ExamReadyState extends ExamState {
  final Exam exam;
  final List<Question> questions;
  
  ExamReadyState({
    required this.exam,
    required this.questions,
  });
}

class ExamErrorState extends ExamState {
  final String message;
  
  ExamErrorState({required this.message});
}

class ExamCompletedState extends ExamState {
  final ExamResult result;
  
  ExamCompletedState({required this.result});
}
```

**✓ Đúng:**

```dart
// ✓ Each state is clear and separate
BlocBuilder<ExamBloc, ExamState>(
  builder: (context, state) {
    return switch(state) {
      ExamInitialState() => const SizedBox(),
      ExamLoadingState() => const CircularProgressIndicator(),
      ExamReadyState s => ExamDisplay(exam: s.exam, questions: s.questions),
      ExamErrorState s => ErrorDialog(message: s.message),
      ExamCompletedState s => ResultsDisplay(result: s.result),
    };
  },
)
```

**✗ Sai:**

```dart
// ❌ Boolean flag hell
class ExamState {
  final bool isLoading;
  final bool hasError;
  final bool isCompleted;
  final Exam? exam;
  final String? errorMessage;
  final ExamResult? result;
  
  ExamState({
    this.isLoading = false,
    this.hasError = false,
    this.isCompleted = false,
    this.exam,
    this.errorMessage,
    this.result,
  });
}

// UI logic becomes messy
if (state.isLoading) {
  // show spinner
} else if (state.hasError) {
  // show error (but which one?)
} else if (state.isCompleted) {
  // show result
} else {
  // show form
}
```

### BLoC Implementation

**`presentation/bloc/exam_bloc.dart`:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository _repository;
  
  ExamAttemptBloc({required ExamRepository repository})
    : _repository = repository,
      super(ExamInitialState()) {
    // Register event handlers
    on<ExamStartedEvent>(_onExamStarted);
    on<ExamAnswerSubmittedEvent>(_onAnswerSubmitted);
    on<ExamCompletedEvent>(_onExamCompleted);
  }
  
  Future<void> _onExamStarted(
    ExamStartedEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(ExamLoadingState());
    try {
      final exam = await _repository.fetchExam(event.examId);
      final questions = await _repository.fetchQuestions(event.examId);
      emit(ExamReadyState(exam: exam, questions: questions));
    } catch (e) {
      emit(ExamErrorState(message: e.toString()));
    }
  }
  
  Future<void> _onAnswerSubmitted(
    ExamAnswerSubmittedEvent event,
    Emitter<ExamState> emit,
  ) async {
    if (state is! ExamReadyState) return;
    
    try {
      await _repository.submitAnswer(
        event.questionId,
        event.response,
      );
      // ✓ Emit new state instead of mutating
      emit(ExamReadyState(
        exam: (state as ExamReadyState).exam,
        questions: (state as ExamReadyState).questions,
      ));
    } catch (e) {
      emit(ExamErrorState(message: e.toString()));
    }
  }
  
  Future<void> _onExamCompleted(
    ExamCompletedEvent event,
    Emitter<ExamState> emit,
  ) async {
    try {
      final result = await _repository.completeExam();
      emit(ExamCompletedState(result: result));
    } catch (e) {
      emit(ExamErrorState(message: e.toString()));
    }
  }
}
```

### UI: Exhaustive Pattern Matching

Dùng **switch expression** để đảm bảo mọi state được xử lý.

**✓ Đúng:**

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<ExamAttemptBloc, ExamState>(
    builder: (context, state) {
      return switch(state) {
        ExamInitialState() => const Center(child: Text('Ready')),
        ExamLoadingState() => const Center(child: CircularProgressIndicator()),
        ExamReadyState s => _buildExamDisplay(s),
        ExamErrorState s => _buildErrorDialog(s),
        ExamCompletedState s => _buildResultsScreen(s),
      };
    },
  );
}

Widget _buildExamDisplay(ExamReadyState state) {
  return Column(
    children: [
      Text(state.exam.title),
      Expanded(
        child: ListView.builder(
          itemCount: state.questions.length,
          itemBuilder: (context, index) {
            return _QuestionCard(question: state.questions[index]);
          },
        ),
      ),
    ],
  );
}
```

**✗ Sai:**

```dart
// ❌ Repository calls in build()
@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: _repository.fetchExam('123'),  // ❌ Direct repository call
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ExamDisplay(exam: snapshot.data);
      } else if (snapshot.hasError) {
        return ErrorWidget();
      }
      return CircularProgressIndicator();
    },
  );
}

// ❌ Missing exhaustive matching
@override
Widget build(BuildContext context) {
  return BlocBuilder<ExamAttemptBloc, ExamState>(
    builder: (context, state) {
      if (state is ExamLoadingState) {
        return CircularProgressIndicator();
      } else if (state is ExamReadyState) {
        return ExamDisplay(exam: state.exam);
      }
      // ❌ ExamErrorState, ExamCompletedState not handled
    },
  );
}
```

---

## Vòng Đời Tài Nguyên (Resource Lifecycle)

### dispose() Pattern

**Bắt buộc override `dispose()` khi State sử dụng:**
- `TextEditingController`
- `AnimationController`
- `ScrollController`
- `FocusNode`
- `StreamSubscription`
- `Timer`

**✓ Đúng:**

```dart
class ExamFormState extends State<ExamForm> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late StreamSubscription _subscription;
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    
    _subscription = examStream.listen((event) {
      setState(() { });
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      // Update timer
    });
  }
  
  @override
  void dispose() {
    // ✓ Dispose in reverse order of creation
    _emailController.dispose();
    _nameController.dispose();
    _subscription.cancel();
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _emailController);
  }
}
```

**✗ Sai:**

```dart
class ExamFormState extends State<ExamForm> {
  late TextEditingController _emailController;
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _subscription = examStream.listen((_) { });
  }
  
  // ❌ Missing dispose() → Memory leak
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _emailController);
  }
}
```

### StreamSubscription Pattern

Luôn **cancel() trong dispose()**.

**✓ Đúng:**

```dart
class ExamTimerState extends State<ExamTimer> {
  late StreamSubscription _timerSubscription;
  int _secondsRemaining = 0;
  
  @override
  void initState() {
    super.initState();
    _timerSubscription = Stream.periodic(
      Duration(seconds: 1),
      (count) => widget.durationSeconds - count,
    ).listen((remaining) {
      setState(() => _secondsRemaining = remaining);
    });
  }
  
  @override
  void dispose() {
    _timerSubscription.cancel();  // ✓ Cancel subscription
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('$_secondsRemaining seconds');
  }
}
```

**✗ Sai:**

```dart
class ExamTimerState extends State<ExamTimer> {
  late StreamSubscription _timerSubscription;
  
  @override
  void initState() {
    super.initState();
    _timerSubscription = Stream.periodic(...).listen((_) { });
  }
  
  @override
  void dispose() {
    // ❌ Forgot to cancel
    super.dispose();
  }
}
```

### BLoC Disposal in dispose()

Nếu State subscribe trực tiếp đến BLoC stream (không dùng BlocBuilder), phải cancel trong dispose().

**✓ Đúng:**

```dart
class MyPageState extends State<MyPage> {
  late StreamSubscription _examSubscription;
  
  @override
  void initState() {
    super.initState();
    _examSubscription = context.read<ExamBloc>().stream.listen((state) {
      // Handle state
    });
  }
  
  @override
  void dispose() {
    _examSubscription.cancel();  // ✓
    super.dispose();
  }
}
```

---

## An Toàn Bất Đồng Bộ (Async Safety)

### Mounted Check After Await

**Không dùng BuildContext sau `await`** mà không kiểm tra `mounted`.

**✓ Đúng:**

```dart
void _submitAnswer() async {
  try {
    // Async work
    await _repository.submitAnswer(answerId, response);
    
    // ✓ Check mounted before using context
    if (!mounted) return;
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(text: AppStrings.answerSubmitted),
    );
  } catch (e) {
    if (!mounted) return;  // ✓ Check again
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(text: 'Error: $e'),
    );
  }
}
```

**✗ Sai:**

```dart
void _submitAnswer() async {
  try {
    await _repository.submitAnswer(answerId, response);
    
    // ❌ Context might be unmounted here (widget popped during async)
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(text: 'Answer submitted'),
    );
  } catch (e) {
    // ❌ Also no check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(text: 'Error: $e'),
    );
  }
}
```

### BLoC Event Handlers (No Context in BLoC)

**BLoC không được dùng BuildContext trực tiếp**. Emit error state thay vì gọi Navigator/ScaffoldMessenger trong BLoC.

**✓ Đúng:**

```dart
// In BLoC event handler
Future<void> _onAnswerSubmitted(
  ExamAnswerSubmittedEvent event,
  Emitter<ExamState> emit,
) async {
  try {
    await _repository.submitAnswer(event.answerId, event.response);
    // Emit success state
    emit(ExamAnswerSuccessState());
  } catch (e) {
    // Emit error state (no context used)
    emit(ExamErrorState(message: e.toString()));
  }
}

// In UI
@override
Widget build(BuildContext context) {
  return BlocListener<ExamBloc, ExamState>(
    listener: (context, state) {
      if (state is ExamErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(text: state.message),
        );
      }
    },
    child: BlocBuilder<ExamBloc, ExamState>(
      builder: (context, state) { /* ... */ },
    ),
  );
}
```

**✗ Sai:**

```dart
// ❌ BLoC using context (WRONG)
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  ExamAttemptBloc(this.context, ...);  // ❌ Context in BLoC
  
  Future<void> _onAnswerSubmitted(...) async {
    try {
      await _repository.submitAnswer(...);
      // ❌ Navigator in BLoC
      Navigator.of(context).pop();
    } catch (e) {
      // ❌ ScaffoldMessenger in BLoC
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }
}
```

### Try-Catch in BLoC Events

Luôn catch exception trong BLoC event handler, emit error state.

**✓ Đúng:**

```dart
Future<void> _onExamStarted(
  ExamStartedEvent event,
  Emitter<ExamState> emit,
) async {
  emit(ExamLoadingState());
  try {
    final exam = await _repository.fetchExam(event.examId);
    emit(ExamReadyState(exam: exam));
  } on NetworkException catch (e) {
    emit(ExamErrorState(message: AppStrings.errorNetwork));
  } on ServerException catch (e) {
    emit(ExamErrorState(message: 'Server error: ${e.code}'));
  } catch (e) {
    emit(ExamErrorState(message: 'Unknown error'));
  }
}
```

**✗ Sai:**

```dart
Future<void> _onExamStarted(
  ExamStartedEvent event,
  Emitter<ExamState> emit,
) async {
  emit(ExamLoadingState());
  final exam = await _repository.fetchExam(event.examId);  // ❌ No try-catch
  emit(ExamReadyState(exam: exam));
}
```

---

## Tối Ưu Hóa Hiệu Suất

### BlocSelector for Partial Rebuilds

Dùng **BlocSelector** khi widget chỉ phụ thuộc 1 field của state, tránh rebuild toàn bộ.

**✓ Đúng:**

```dart
// ✓ Rebuild chỉ khi isLoading thay đổi
BlocSelector<ExamBloc, ExamState, bool>(
  selector: (state) => state is ExamLoadingState,
  builder: (context, isLoading) {
    return isLoading
      ? const CircularProgressIndicator()
      : const SizedBox();
  },
)

// ✓ Rebuild chỉ khi exam title thay đổi
BlocSelector<ExamBloc, ExamState, String>(
  selector: (state) => state is ExamReadyState
    ? state.exam.title
    : '',
  builder: (context, title) => Text(title),
)
```

**✗ Sai:**

```dart
// ❌ Rebuild toàn bộ dù chỉ dùng 1 field
BlocBuilder<ExamBloc, ExamState>(
  builder: (context, state) {
    if (state is ExamLoadingState) {
      return CircularProgressIndicator();
    } else if (state is ExamReadyState) {
      return Text(state.exam.title);  // Rebuild cả state chỉ vì title thay đổi
    }
    return SizedBox();
  },
)
```

### Const Constructors and Keys

Dùng **const** để tránh rebuild không cần thiết. Dùng **Key** cho stateful widgets trong list.

**✓ Đúng:**

```dart
ListView.builder(
  itemCount: questions.length,
  itemBuilder: (context, index) {
    return QuestionCard(
      key: ValueKey(questions[index].id),  // ← Preserve state on reorder
      question: questions[index],
    );
  },
)

// Const widget
const SizedBox(
  height: AppDimensions.spacingMedium,
  child: Divider(),  // ← Const, won't rebuild
)
```

**✗ Sai:**

```dart
ListView.builder(
  itemCount: questions.length,
  itemBuilder: (context, index) {
    return QuestionCard(  // ❌ No key, state lost on reorder
      question: questions[index],
    );
  },
)

// ❌ No const
SizedBox(
  height: AppDimensions.spacingMedium,
  child: Divider(),  // Will rebuild unnecessarily
)
```

### Lazy Loading

Dùng `ListView.builder` thay vì `ListView`, dùng `Image.network` thay vì pre-download.

**✓ Đúng:**

```dart
// ✓ Lazy load questions
ListView.builder(
  itemCount: _questions.length,
  itemBuilder: (context, index) => QuestionCard(question: _questions[index]),
)

// ✓ Lazy load image
Image.network(
  'https://api.aptis.edu/images/exam-${examId}.png',
  fit: BoxFit.cover,
  placeholder: (context, url) => const Placeholder(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)
```

**✗ Sai:**

```dart
// ❌ Load all questions upfront
ListView(
  children: _questions.map((q) => QuestionCard(question: q)).toList(),
)

// ❌ No placeholder
Image.asset('assets/exam-$examId.png')  // Blocks build if file large
```

---

## Những Lỗi Phổ Biến

1. **Memory Leak: Quên dispose()** → TextEditingController, StreamSubscription không được giải phóng, crash on hot reload.
   - Fix: Luôn override `dispose()` và gọi `super.dispose()` cuối cùng.

2. **BlocListener inside build()** → Listener gọi nhiều lần, side effect phát sinh lặp lại.
   - Fix: Đặt BlocListener ở ngoài BlocBuilder hoặc dùng `listenWhen`.

3. **Passing entire state to BlocBuilder** → Widget rebuild dù chỉ 1 field thay đổi.
   - Fix: Dùng `BlocSelector` để select 1 field.

4. **Hardcoded string in widget** → Vi phạm constants rule, khó maintain.
   - Fix: Dùng `AppStrings.xxx` từ `lib/core/constants/app_strings.dart`.

5. **Mutable state in const widget** → Widget được const nhưng có mutable field, unexpected rebuild.
   - Fix: Kiểm tra tất cả field trong const widget là immutable.

6. **Catch generic Exception** → Swallow errors, khó debug.
   - Fix: Catch specific exception type (NetworkException, ServerException, etc.).

7. **No mounted check after await** → Crash khi dùng context sau pop.
   - Fix: Thêm `if (!mounted) return;` sau mọi await.

8. **BLoC event handler calls repository directly in build()** → Gọi API mỗi lần rebuild.
   - Fix: Dispatch event từ UI, BLoC handle trong event listener.

9. **No error state emission** → UI hang khi error xảy ra.
   - Fix: Emit error state từ BLoC event handler.

10. **Forgetting to cancel StreamSubscription** → Memory leak.
    - Fix: Call `_subscription.cancel()` trong `dispose()`.

11. **Using BuildContext in BLoC** → BLoC tight-coupled với Flutter, khó test.
    - Fix: Không dùng context trong BLoC, emit state thay vì call Navigator.

12. **No const constructor on widget** → Widget rebuild unnecessarily.
    - Fix: Add `const` to widget constructor if no mutable state.

---

## Danh Sách Kiểm Tra Code Review

Trước khi merge PR, verify các items sau:

### 1. Hằng Số & Strings

- [ ] **Không hardcoded string trong widget** → Tất cả user-facing message phải dùng `AppStrings.xxx` từ `lib/core/constants/app_strings.dart`.
  - Kiểm tra: `grep -r '"' features/*/presentation/pages/ features/*/presentation/widgets/` không có string literal ngoài AppStrings.

- [ ] **Tất cả color dùng AppColors.xxx hoặc Theme.of(context)** → Không `Color(0xFF...)` hardcode.
  - Kiểm tra: `grep -r 'Color(0x' lib/` không tìm thấy.

- [ ] **Tất cả dimension (spacing, radius) dùng AppDimensions.xxx** → Không hardcode `16`, `8`, `4`.
  - Kiểm tra: SizedBox(height: 16) → SizedBox(height: AppDimensions.spacingMedium).

### 2. File Size & Structure

- [ ] **File < 300 dòng** (BLoC exception: bloc/event/state có thể là 3 file, mỗi file <150 dòng).
  - Kiểm tra: `wc -l filename.dart` không vượt 300.

- [ ] **Folder structure đúng** → Feature có đầy đủ data → domain → presentation layers.
  - Kiểm tra: `ls features/{name}/` có data/, domain/, presentation/, {feature}_module.dart.

- [ ] **Shared widget nằm trong lib/core/widgets/** → Nếu widget dùng ở 2+ feature, phải extract lên.
  - Kiểm tra: Không copy-paste widget code qua 2 file.

### 3. BLoC Pattern

- [ ] **Event là sealed class** → Type safety + exhaustive matching.
  - Kiểm tra: `sealed class XyzEvent {}` trong event file.

- [ ] **State là separate immutable classes, NOT boolean flags** → Không `isLoading`, `hasError` flag.
  - Kiểm tra: State file có class XyzLoadingState, XyzErrorState (không 1 class với flags).

- [ ] **Exhaustive pattern matching** → Mọi state được handle trong UI.
  - Kiểm tra: `switch(state) { ... }` cover tất cả state case.

- [ ] **BLoC event handler có try-catch** → Emit error state, không let exception bubble.
  - Kiểm tra: `_onXyz(..., Emitter emit) async { try { } catch (e) { emit(ErrorState) } }`.

- [ ] **Không gọi repository trong build()** → Chỉ dispatch event, BLoC xử lý.
  - Kiểm địm: build() không có `await _repository`, `_repository.fetch()`.

### 4. Widget Decomposition

- [ ] **build() < 50 dòng** → Nếu vượt, extract sub-widget.
  - Kiểm tra: Count lines trong build() method.

- [ ] **Const constructor khi không có mutable state** → Tránh rebuild không cần.
  - Kiểm tra: Stateless widget có `const Xyz({...})`.

- [ ] **BlocBuilder/BlocListener ngoài build()** → Không nested inside build, tránh multiple calls.
  - Kiểm tra: BlocBuilder là top-level widget, không inside Column/Row.

### 5. Resource Lifecycle

- [ ] **Mọi State với TextEditingController/AnimationController/StreamSubscription có dispose()**
  - Kiểm tra: State class có `@override void dispose() { _controller.dispose(); super.dispose(); }`.

- [ ] **Gọi super.dispose() cuối cùng** → Không забыть.
  - Kiểm tra: `super.dispose();` là dòng cuối trong dispose().

- [ ] **StreamSubscription.cancel() trong dispose()**
  - Kiểm tra: `_subscription?.cancel();` trước `super.dispose()`.

### 6. Async Safety

- [ ] **Kiểm tra mounted sau await** → Không context crash.
  - Kiểm tra: Sau `await`, trước `Navigator.of(context)` hoặc `ScaffoldMessenger`, có `if (!mounted) return;`.

- [ ] **Không BuildContext trong BLoC** → BLoC event handler không call Navigator/ScaffoldMessenger.
  - Kiểm tra: BLoC file không import `'package:flutter/material.dart'`.

- [ ] **Error handling trong async** → Không unhandled exception.
  - Kiểm tra: try-catch bao quanh `await` call.

### 7. Naming & Conventions

- [ ] **File snake_case** → `exam_bloc.dart`, không `ExamBloc.dart`.
  - Kiểm tra: `ls features/*/presentation/bloc/`.

- [ ] **Class PascalCase** → `ExamAttemptBloc`, `ExamReadyState`.
  - Kiểm tra: grep `class [a-z]` không tìm thấy.

- [ ] **Method/variable camelCase** → `loadExam()`, `studentId`.
  - Kiểm tra: grep `def [A-Z]` (nếu dùng method naming pattern không common).

- [ ] **Constant lowerCamelCase const** → `const String examNotFound = '...'`.
  - Kiểm tra: `const String EXAM_NOT_FOUND` (uppercase) là sai.

- [ ] **Private member prefix `_`** → `_repository`, `_controller`.
  - Kiểm tra: Field không exported không có `_` là code smell.

### 8. SOLID Principles

- [ ] **Repository abstract, không hardcode Impl** → DI qua constructor, GetIt.
  - Kiểm tra: BLoC constructor có `final ExamRepository _repo`, không `ExamRepositoryImpl`.

- [ ] **Dependency injection via GetIt, không new RepositoryImpl()**
  - Kiểm tra: main.dart setupExamModule() gọi `getIt.registerSingleton(...)`.

- [ ] **1 BLoC per feature flow** → Không god BLoC.
  - Kiểm tra: ExamBloc xử lý exam taking, ResultBloc xử lý result.

### 9. Performance

- [ ] **Dùng BlocSelector khi chỉ 1 field cần rebuild**
  - Kiểm tra: Nếu build() chỉ dùng state.isLoading, dùng `BlocSelector<..., bool>`.

- [ ] **Const constructor trên widget**
  - Kiểm tra: StatelessWidget không có mutable field → `const Widget({...})`.

- [ ] **ListView.builder, không ListView** → Lazy load.
  - Kiểm tra: Danh sách dài dùng `.builder`, không tạo all items upfront.

### 10. Testing & Code Quality

- [ ] **No commented-out code** → Xóa dead code, Git lưu history.
  - Kiểm tra: `grep -r '^\s*//' features/` hoặc multi-line comment block.

- [ ] **No magic number/string** → `const int MAX_RETRIES = 5` thay vì `if (count > 5)`.
  - Kiểm tra: Không hardcode number trong logic (ngoài UI dimension).

- [ ] **Comment giải thích WHY, không WHAT** → Code đã nói WHAT.
  - Kiểm tra: Comment chỉ cho business rule, constraint, workaround.

---

## Ví Dụ Complete Feature

### Feature: ExamAttempt

**`features/exam/domain/entities/exam.dart`:**

```dart
class Exam {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final List<Question> questions;
  
  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.questions,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  
  Question({
    required this.id,
    required this.text,
    required this.options,
  });
}
```

**`features/exam/domain/repositories/exam_repository.dart`:**

```dart
abstract class ExamRepository {
  Future<Exam> fetchExam(String examId);
  Future<void> submitAnswer(String questionId, String response);
  Future<ExamResult> completeExam(String examId);
}
```

**`features/exam/presentation/bloc/exam_event.dart`:**

```dart
sealed class ExamEvent {}

class ExamStartedEvent extends ExamEvent {
  final String examId;
  ExamStartedEvent({required this.examId});
}

class ExamAnswerSubmittedEvent extends ExamEvent {
  final String questionId;
  final String response;
  
  ExamAnswerSubmittedEvent({
    required this.questionId,
    required this.response,
  });
}

class ExamCompletedEvent extends ExamEvent {
  final String examId;
  ExamCompletedEvent({required this.examId});
}
```

**`features/exam/presentation/bloc/exam_state.dart`:**

```dart
abstract class ExamState {}

class ExamInitialState extends ExamState {}

class ExamLoadingState extends ExamState {}

class ExamReadyState extends ExamState {
  final Exam exam;
  ExamReadyState({required this.exam});
}

class ExamErrorState extends ExamState {
  final String message;
  ExamErrorState({required this.message});
}

class ExamCompletedState extends ExamState {
  final ExamResult result;
  ExamCompletedState({required this.result});
}
```

**`features/exam/presentation/bloc/exam_bloc.dart`:**

```dart
class ExamAttemptBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository _repository;
  
  ExamAttemptBloc({required ExamRepository repository})
    : _repository = repository,
      super(ExamInitialState()) {
    on<ExamStartedEvent>(_onExamStarted);
    on<ExamAnswerSubmittedEvent>(_onAnswerSubmitted);
    on<ExamCompletedEvent>(_onExamCompleted);
  }
  
  Future<void> _onExamStarted(
    ExamStartedEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(ExamLoadingState());
    try {
      final exam = await _repository.fetchExam(event.examId);
      emit(ExamReadyState(exam: exam));
    } catch (e) {
      emit(ExamErrorState(message: AppStrings.errorLoadingExam));
    }
  }
  
  Future<void> _onAnswerSubmitted(
    ExamAnswerSubmittedEvent event,
    Emitter<ExamState> emit,
  ) async {
    try {
      await _repository.submitAnswer(event.questionId, event.response);
    } catch (e) {
      emit(ExamErrorState(message: AppStrings.errorSubmittingAnswer));
    }
  }
  
  Future<void> _onExamCompleted(
    ExamCompletedEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(ExamLoadingState());
    try {
      final result = await _repository.completeExam(event.examId);
      emit(ExamCompletedState(result: result));
    } catch (e) {
      emit(ExamErrorState(message: AppStrings.errorNetwork));
    }
  }
}
```

**`features/exam/presentation/pages/exam_page.dart`:**

```dart
class ExamPage extends StatelessWidget {
  final String examId;
  
  const ExamPage({required this.examId});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<ExamAttemptBloc>()
        ..add(ExamStartedEvent(examId: examId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: BlocBuilder<ExamAttemptBloc, ExamState>(
          builder: (context, state) {
            return switch(state) {
              ExamInitialState() => const SizedBox(),
              ExamLoadingState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ExamReadyState s => ExamDisplay(exam: s.exam),
              ExamErrorState s => Center(child: Text(s.message)),
              ExamCompletedState s => ResultsDisplay(result: s.result),
            };
          },
        ),
      ),
    );
  }
}
```

**`features/exam/presentation/widgets/exam_display.dart`:**

```dart
class ExamDisplay extends StatelessWidget {
  final Exam exam;
  
  const ExamDisplay({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExamHeader(exam: exam),
        Expanded(
          child: ListView.builder(
            itemCount: exam.questions.length,
            itemBuilder: (context, index) {
              return QuestionCard(
                key: ValueKey(exam.questions[index].id),
                question: exam.questions[index],
              );
            },
          ),
        ),
        _ExamFooter(exam: exam),
      ],
    );
  }
}

class _ExamHeader extends StatelessWidget {
  final Exam exam;
  const _ExamHeader({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.title,
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            exam.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExamFooter extends StatelessWidget {
  final Exam exam;
  const _ExamFooter({required this.exam});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: ElevatedButton(
        onPressed: () {
          context.read<ExamAttemptBloc>().add(
            ExamCompletedEvent(examId: exam.id),
          );
        },
        child: const Text(AppStrings.buttonSubmit),
      ),
    );
  }
}
```

**`features/exam/exam_module.dart`:**

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupExamModule() {
  // Register repository
  getIt.registerSingleton<ExamRepository>(
    ExamRepositoryImpl(apiClient: getIt()),
  );
  
  // Register BLoC
  getIt.registerSingleton<ExamAttemptBloc>(
    ExamAttemptBloc(repository: getIt()),
  );
}
```

---

## Kết Luận

Tài liệu này thiết lập baseline cho toàn bộ team Aptis App. Mục tiêu là:

1. **Consistency** — Mọi developer code cùng phong cách.
2. **Readability** — Người mới dễ hiểu code cũ.
3. **Maintainability** — Ít bug, dễ refactor.
4. **Performance** — Tránh memory leak, rebuild unnecessary.
5. **Testability** — Dependency injection, separation of concerns.

Khi review PR, sử dụng [Danh Sách Kiểm Tra Code Review](#danh-sách-kiểm-tra-code-review) ở trên. Nếu gặp violation, yêu cầu tác giả fix trước merge.

**Happy coding!** 🚀

---

**Phiên bản:** 1.0  
**Ngày cập nhật:** 2026-06-24  
**Liên hệ:** Mobile Team @ Aptis
