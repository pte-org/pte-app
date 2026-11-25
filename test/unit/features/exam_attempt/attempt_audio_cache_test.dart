import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';

class _FakeAudioAdapter implements HttpClientAdapter {
  _FakeAudioAdapter({this.failingUrls = const {}});

  final Set<String> failingUrls;
  final requested = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options);
    if (failingUrls.contains(options.uri.toString())) {
      return ResponseBody.fromString('nope', 500);
    }
    return ResponseBody.fromBytes(
      Uint8List.fromList([1, 2, 3, 4]),
      200,
      headers: {
        Headers.contentLengthHeader: ['4'],
      },
    );
  }
}

void main() {
  late Directory tempRoot;
  late Directory cacheRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('attempt_audio_test');
    cacheRoot = Directory('${tempRoot.path}/cache');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  AttemptAudioCache build(_FakeAudioAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return AttemptAudioCache(dio: dio, rootProvider: () async => cacheRoot);
  }

  test('downloads http(s) audio and maps the url to a local file', () async {
    final adapter = _FakeAudioAdapter();
    final cache = build(adapter);

    await cache.prefetch(['https://cdn.test/a.mp3', 'https://cdn.test/b.wav']);

    final a = cache.localPathFor('https://cdn.test/a.mp3');
    final b = cache.localPathFor('https://cdn.test/b.wav');
    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(a, endsWith('.mp3'));
    expect(b, endsWith('.wav'));
    expect(File(a!).readAsBytesSync(), [1, 2, 3, 4]);
    expect(a, isNot(contains('cdn.test')));
  });

  test('never sends an Authorization header', () async {
    final adapter = _FakeAudioAdapter();
    await build(adapter).prefetch(['https://cdn.test/a.mp3']);

    expect(adapter.requested, hasLength(1));
    expect(
      adapter.requested.single.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('authorization')),
    );
  });

  test('skips null, empty, asset and already cached sources', () async {
    final adapter = _FakeAudioAdapter();
    final cache = build(adapter);

    await cache.prefetch([null, '', 'assets/audio/sample.wav']);
    expect(adapter.requested, isEmpty);

    await cache.prefetch(['https://cdn.test/a.mp3']);
    await cache.prefetch(['https://cdn.test/a.mp3']);
    expect(adapter.requested, hasLength(1));
  });

  test('a failed download is skipped so playback can stream instead', () async {
    final adapter = _FakeAudioAdapter(failingUrls: {'https://cdn.test/bad.mp3'});
    final cache = build(adapter);

    await cache.prefetch(['https://cdn.test/bad.mp3', 'https://cdn.test/ok.mp3']);

    expect(cache.localPathFor('https://cdn.test/bad.mp3'), isNull);
    expect(cache.localPathFor('https://cdn.test/ok.mp3'), isNotNull);
  });

  test('clear deletes the files and forgets every url', () async {
    final cache = build(_FakeAudioAdapter());
    await cache.prefetch(['https://cdn.test/a.mp3']);
    final path = cache.localPathFor('https://cdn.test/a.mp3')!;

    await cache.clear();

    expect(File(path).existsSync(), isFalse);
    expect(cache.localPathFor('https://cdn.test/a.mp3'), isNull);
  });

  test('wipes files left behind by an earlier run on first download', () async {
    await cacheRoot.create(recursive: true);
    final stale = File('${cacheRoot.path}/leftover.mp3')..writeAsBytesSync([9]);

    await build(_FakeAudioAdapter()).prefetch(['https://cdn.test/a.mp3']);

    expect(stale.existsSync(), isFalse);
  });

  test('a cached file removed from disk falls back to streaming', () async {
    final cache = build(_FakeAudioAdapter());
    await cache.prefetch(['https://cdn.test/a.mp3']);
    File(cache.localPathFor('https://cdn.test/a.mp3')!).deleteSync();

    expect(cache.localPathFor('https://cdn.test/a.mp3'), isNull);
  });
}
