import 'package:record/record.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

/// `audio/wav` — matches [AudioEncoder.wav] below, one of the three
/// `contentType` values `POST /api/v1/objects` accepts (phase-06
/// Design Constraints).
const String readAloudContentType = 'audio/wav';

/// How often [AudioRecorderServiceImpl.inputLevels] samples the mic.
const Duration _inputLevelInterval = Duration(milliseconds: 100);

class AudioRecorderServiceImpl implements AudioRecorderService {
  AudioRecorderServiceImpl({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<void> start(String filePath) async {
    if (!await _recorder.hasPermission() ||
        (await _recorder.listInputDevices()).isEmpty) {
      throw const AudioInputUnavailableException();
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, autoGain: true),
      path: filePath,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<bool> isRecording() => _recorder.isRecording();

  /// Cached so every caller gets the same stream instance — widgets compare
  /// it across rebuilds to avoid resubscribing.
  @override
  late final Stream<double> inputLevels = _recorder
      .onAmplitudeChanged(_inputLevelInterval)
      .map((amplitude) => amplitude.current);
}
