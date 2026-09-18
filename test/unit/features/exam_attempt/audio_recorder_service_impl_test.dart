import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/data/audio_recorder_service_impl.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RecordConfig());
  });

  late _MockAudioRecorder recorder;
  late AudioRecorderServiceImpl service;

  setUp(() {
    recorder = _MockAudioRecorder();
    service = AudioRecorderServiceImpl(recorder: recorder);
  });

  test('does not call native start when permission is denied', () async {
    when(() => recorder.hasPermission()).thenAnswer((_) async => false);

    await expectLater(
      service.start('/tmp/answer.wav'),
      throwsA(isA<AudioInputUnavailableException>()),
    );

    verifyNever(() => recorder.start(any(), path: any(named: 'path')));
  });

  test('does not call native start when no input device is present', () async {
    when(() => recorder.hasPermission()).thenAnswer((_) async => true);
    when(() => recorder.listInputDevices()).thenAnswer((_) async => const []);

    await expectLater(
      service.start('/tmp/answer.wav'),
      throwsA(isA<AudioInputUnavailableException>()),
    );

    verifyNever(() => recorder.start(any(), path: any(named: 'path')));
  });

  test(
    'starts WAV recording only after a usable input device is found',
    () async {
      when(() => recorder.hasPermission()).thenAnswer((_) async => true);
      when(() => recorder.listInputDevices()).thenAnswer(
        (_) async => const [InputDevice(id: 'mic-1', label: 'Built-in mic')],
      );
      when(
        () => recorder.start(any(), path: any(named: 'path')),
      ).thenAnswer((_) async {});

      await service.start('/tmp/answer.wav');

      verify(
        () => recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: '/tmp/answer.wav',
        ),
      ).called(1);
    },
  );
}
