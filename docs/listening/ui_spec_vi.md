# Đặc tả Giao diện (UI Specification) - Phần Listening

**Module:** `features/listening`

## 1. Tổng quan Kiến trúc
Bài thi Listening của Aptis bao gồm 4 Part riêng biệt. Tuy nhiên, xét dưới góc độ thiết kế giao diện (UI), 4 Part này thực chất chỉ chia sẻ 2 cấu trúc hiển thị cốt lõi. Để đảm bảo code không bị lặp lại (DRY) và dễ bảo trì, phần UI đã được hợp nhất thành **hai template trang (page) có thể tái sử dụng**.

- **Part 1 & Part 3**: Được xử lý bởi `ListeningMultipleChoicePage`.
- **Part 2 & Part 4**: Được xử lý bởi `ListeningMatchingPage`.

Cả hai trang này đều được bọc bên trong widget tổng `ExamScaffold` để duy trì sự đồng bộ cho toàn bộ ứng dụng (giữ nguyên thanh thời gian, thanh điều hướng dưới cùng, nút cắm cờ, v.v.).

---

## 2. Các Page Template

### 2.1. `ListeningMultipleChoicePage`
**Sử dụng cho:** Part 1 (1 câu hỏi duy nhất, 3-4 đáp án) & Part 3 (Nhiều câu hỏi, 3-4 đáp án).
**Đường dẫn:** `lib/features/listening/presentation/pages/listening/listening_multiple_choice_page.dart`

**Tính năng chính:**
- Tiếp nhận một danh sách (List) các câu hỏi linh động.
- Nếu chỉ truyền vào 1 câu hỏi (như Part 1), trang sẽ hiển thị bình thường ngay bên dưới thanh Audio.
- Nếu truyền vào nhiều câu hỏi (như Part 3), trang sẽ tự động cuộn (scroll) danh sách các câu hỏi này bên dưới thanh Audio.
- Hỗ trợ số lượng đáp án bất kỳ cho mỗi câu hỏi (thường là 3 hoặc 4) thông qua việc render danh sách các widget `MultipleChoiceOption`.

### 2.2. `ListeningMatchingPage`
**Sử dụng cho:** Part 2 (Các câu cần điền từ/mệnh đề ngắn) & Part 4 (Các quan điểm/phát biểu dài).
**Đường dẫn:** `lib/features/listening/presentation/pages/listening/listening_matching_page.dart`

**Tính năng chính:**
- Được xây dựng để xử lý các câu hỏi dạng "Nối đáp án" (Matching) bằng cách sử dụng các thanh Dropdown.
- Sử dụng widget `DropdownMatchingList` để render danh sách các phát biểu, mỗi phát biểu đi kèm với một hộp Dropdown để chọn đáp án tương ứng.
- Thiết kế rất linh hoạt về độ dài của văn bản. Nhãn văn bản (Label) được bọc trong widget `Expanded` nên các câu văn dài (như phần nhận định trong Part 4) có thể tự động xuống dòng tự nhiên mà không làm tràn (overflow) layout, trong khi hộp Dropdown vẫn luôn được căn lề phải gọn gàng.

---

## 3. Các Widget Thành phần (Core Widgets)

### 3.1. `AudioPlayerBar`
**Đường dẫn:** `lib/features/listening/presentation/widgets/listening/audio_player_bar.dart`
- Là một template UI tĩnh đại diện cho thanh phát Audio màu đỏ.
- Sử dụng mã màu `AppColors.accentRed` và kéo dài toàn bộ chiều ngang của màn hình (edge-to-edge).
- Hiện tại đóng vai trò là placeholder trực quan, sẵn sàng để tích hợp logic với các thư viện xử lý âm thanh (ví dụ: `just_audio` hoặc `audioplayers`) sau khi các Domain Model ở backend được hoàn thiện.

### 3.2. `MultipleChoiceOption`
**Đường dẫn:** `lib/features/listening/presentation/widgets/listening/multiple_choice_option.dart`
- Một component có thể tái sử dụng để render từng dòng đáp án dạng nút Radio (Trắc nghiệm).
- Tự động in đậm chữ cái của đáp án (ví dụ: "**A.** 4.00 pm").
- Được vẽ (build) bằng các container hình tròn tuỳ chỉnh nhằm mô phỏng chính xác nhất thiết kế gốc của Aptis.

### 3.3. `DropdownMatchingList`
**Đường dẫn:** `lib/features/listening/presentation/widgets/listening/dropdown_matching_list.dart`
- Component danh sách tái sử dụng để render các hàng có cấu trúc `Văn bản (Label) + Dropdown`.
- Nhận đầu vào là một List các Label và một List 2 chiều chứa các đáp án (cho từng Dropdown).
- Tự động kích hoạt callback `onChanged(index, value)` bất cứ khi nào người dùng chọn một mục mới từ bất kỳ dropdown nào trong danh sách.

---

## 4. Ghi chú Kỹ thuật (Ràng buộc Layout)
Do `ExamScaffold` mặc định đã cung cấp sẵn một khung cuộn `SingleChildScrollView` ở lớp ngoài cùng (khi `scrollableBody: true`), nếu chúng ta đặt một `Column` chứa widget `Expanded` vào bên trong đó sẽ gây ra lỗi giới hạn chiều cao không xác định (lỗi `RenderFlex` - Unbounded Height).

Để giải quyết triệt để vấn đề này, cả hai trang `ListeningMultipleChoicePage` và `ListeningMatchingPage` đều được truyền cờ `scrollableBody: false` vào `ExamScaffold`. Việc này giúp vô hiệu hoá thanh cuộn lớp ngoài, cho phép các trang Listening tự do quản lý cơ chế cuộn (`SingleChildScrollView`) ở nội bộ của chính nó một cách hoàn hảo.
