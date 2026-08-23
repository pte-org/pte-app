import 'package:record/record.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

/// `audio/wav` — matches [AudioEncoder.wav] below, one of the three
/// `contentType` values `POST /api/media/objects` accepts (phase-06
/// Design Constraints).
const String readAloudContentType = 'audio/wav';

class AudioRecorderServiceImpl implements AudioRecorderService {
  AudioRecorderServiceImpl({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<void> start(String filePath) {
    return _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<bool> isRecording() => _recorder.isRecording();
}
