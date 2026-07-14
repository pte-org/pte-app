# Tài liệu Tích hợp API và UI (Listening Module)

Tài liệu này mô tả chi tiết cách Frontend (Flutter) tiếp nhận và xử lý dữ liệu từ Backend API (cấu trúc **QuestionBank V4 Flat Model** và **Asset Entity**) để hiển thị lên các UI Components của phần thi Listening.

---

## 1. Tổng quan Kiến trúc Dữ liệu (Backend V4)

Theo thiết kế hệ thống mới nhất của API, dữ liệu câu hỏi được "làm phẳng" (flattened):
- **Không còn** các object lồng nhau như `QuestionOption` hay `Passage`.
- Toàn bộ nội dung câu hỏi nằm trong chuỗi `content`.
- Mảng `options` chứa tất cả các lựa chọn dưới dạng `List<String>`.
- Đối với file Audio, do Listening Audio là tài nguyên công khai (`audio_listening`), API sẽ đính kèm trực tiếp đường dẫn CDN (`assetCdnUrl`) vào JSON của câu hỏi.

---

## 2. Model Dữ liệu (`Question.dart`)

Lớp model `Question` đóng vai trò là DTO (Data Transfer Object) để hứng dữ liệu trả về từ API.

**Đường dẫn:** `lib/features/listening/data/models/question.dart`

**Các trường dữ liệu quan trọng:**
- `int part`: Xác định câu hỏi thuộc Part nào (1, 2, 3, 4) để định tuyến UI tương ứng.
- `String questionType`: `MULTIPLE_CHOICE` hoặc `MATCHING`.
- `String content`: Chứa văn bản câu hỏi, đặc biệt chứa thẻ đục lỗ `[Blank X]` cho các câu hỏi Matching.
- `List<String> options`: Mảng các lựa chọn.
- `String? assetCdnUrl`: Đường dẫn trực tiếp đến file Audio trên CDN.
- `int? maxPlayCount`: Số lần tối đa thí sinh được phép nghe audio.

---

## 3. Bộ chuyển đổi Dữ liệu (`ListeningQuestionMapper`)

Do dữ liệu API ở dạng phẳng, nhưng UI lại cần các Model có cấu trúc phân tầng (`MultipleChoiceUIModel` và `MatchingUIModel`), lớp `ListeningQuestionMapper` được tạo ra để đảm nhiệm vai trò trung gian.

**Đường dẫn:** `lib/features/listening/domain/mappers/listening_question_mapper.dart`

### 3.1. Xử lý Multiple Choice (Part 1, 3)
Hàm `mapToMultipleChoice(Question q)`:
- Nếu `content` có chứa ký tự xuống dòng (`\n`), mapper sẽ tách chuỗi ra thành nhiều câu hỏi nhỏ (phục vụ Part 3).
- Cắt mảng `options` gốc ra thành các mảng con bằng nhau, chia đều cho số lượng câu hỏi nhỏ.

### 3.2. Xử lý Matching (Part 2, 4)
Hàm `mapToMatching(Question q)`:
- Sử dụng biểu thức chính quy (Regex) `\[Blank\s*\d+\]` để dò tìm các điểm đục lỗ trong chuỗi `content`.
- **Labels:** Toàn bộ phần text đứng trước mỗi thẻ `[Blank X]` trên cùng một dòng sẽ được cắt ra làm Label (ví dụ: "Speaker A wants to").
- **Options List:** Tương tự Multiple Choice, mảng `options` khổng lồ sẽ được chia nhỏ thành các cụm đều nhau và map vào từng dropdown tương ứng với mỗi Label.
- Những dòng text không chứa `[Blank]` sẽ được gom lại làm `instruction` và `subInstruction` hiển thị ở phần tiêu đề trang.

---

## 4. Tích hợp Audio Player (`AudioPlayerBar`)

Trình phát âm thanh `AudioPlayerBar` là một `StatefulWidget` chịu trách nhiệm stream trực tiếp file audio từ CDN và kiểm soát luồng nghiệp vụ của kỳ thi (số lần nghe).

**Đường dẫn:** `lib/features/listening/presentation/widgets/listening/audio_player_bar.dart`

### 4.1. Thư viện sử dụng
- **Package:** `just_audio` (Phiên bản: `^0.10.6`)
- **Lý do:** Hỗ trợ cực tốt việc theo dõi State mạng (Buffering, Loading, Completed) và không cần down file về máy.

### 4.2. Quản lý trạng thái (State)
- **Truyền URL:** Widget nhận vào `assetCdnUrl` từ `Question` model và gọi `_player.setUrl()`.
- **Đồng bộ UI:** Sử dụng `StreamBuilder` trên `playerStateStream` và `positionStream` để hiển thị:
  - Nút Play/Pause.
  - Vòng xoay Loading khi mạng chậm (Buffering).
  - Thanh tiến trình (Linear Progress Bar).

### 4.3. Luật giới hạn số lần nghe (Max Play Count)
- Widget lưu trữ biến đếm cục bộ `int _playCount = 0;`.
- Lắng nghe event từ Stream: Nếu `processingState == ProcessingState.completed` (Audio chạy hết bài), biến `_playCount` được cộng thêm 1.
- Nếu `_playCount >= maxPlayCount`, giao diện nút Play lập tức bị khóa (vô hiệu hóa sự kiện `onPressed` và làm mờ màu icon).

---

## 5. Quy trình gọi UI
1. API gọi về trả ra object `Question`.
2. Kiểm tra `part`:
   - Nếu `part == 1 || part == 3` -> Trả ra `ListeningMultipleChoicePage(questionData: question)`.
   - Nếu `part == 2 || part == 4` -> Trả ra `ListeningMatchingPage(questionData: question)`.
3. Hàm `initState()` của các Page sẽ tự động gọi Mapper để nạp dữ liệu vào State cục bộ và tiến hành vẽ Widget.
4. Trải nghiệm người dùng hoàn toàn mượt mà nhờ việc xử lý ngầm (Mapper) và streaming audio (just_audio).
