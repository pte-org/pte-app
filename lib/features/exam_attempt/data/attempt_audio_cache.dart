import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/core/config/app_config.dart';

const _cacheDirName = 'pte_attempt_audio';
const _maxParallelDownloads = 3;
const _knownExtensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg', '.opus'};

/// Keeps a local copy of an attempt's listening audio so a prompt still
/// plays after the network drops mid-exam.
///
/// Files live in a private temp folder under random names and are deleted by
/// [clear] when the attempt ends. A leftover folder from an earlier run
/// (crash, force-quit) is wiped before the first download of a new run.
///
/// Downloads never carry the app bearer token: the audio URL itself is the
/// credential, so this uses its own Dio without the gateway interceptors
/// (same rule as `RawUploadClient`).
class AttemptAudioCache {
  AttemptAudioCache({Dio? dio, Future<Directory> Function()? rootProvider})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.uploadReceiveTimeout,
            ),
          ),
      _rootProvider = rootProvider ?? _defaultRoot;

  final Dio _dio;
  final Future<Directory> Function() _rootProvider;
  final Map<String, String> _pathsByUrl = {};
  final Map<String, Future<void>> _inFlight = {};
  final Random _random = Random.secure();
  Future<Directory>? _rootFuture;
  bool _staleSwept = false;
  int _generation = 0;

  static Future<Directory> _defaultRoot() async {
    final temp = await getTemporaryDirectory();
    return Directory(p.join(temp.path, _cacheDirName));
  }

  /// Local file for [url] if it has already been downloaded, else null.
  String? localPathFor(String? url) {
    if (url == null) return null;
    final path = _pathsByUrl[url];
    if (path == null) return null;
    if (!File(path).existsSync()) {
      _pathsByUrl.remove(url);
      return null;
    }
    return path;
  }

  /// Downloads every distinct http(s) URL in [urls] that is not cached yet.
  /// A failed download is skipped: playback then streams that URL as before.
  Future<void> prefetch(Iterable<String?> urls) async {
    final wanted = <String>{
      for (final url in urls)
        if (url != null &&
            (url.startsWith('http://') || url.startsWith('https://')))
          url,
    }.where((url) => localPathFor(url) == null).toList();
    if (wanted.isEmpty) return;

    final generation = _generation;
    final root = await _prepareRoot();
    for (var i = 0; i < wanted.length; i += _maxParallelDownloads) {
      if (generation != _generation) return;
      final batch = wanted.skip(i).take(_maxParallelDownloads);
      await Future.wait(
        batch.map((url) => _download(url, root, generation)),
      );
    }
  }

  /// Deletes every cached file. Downloads still running are discarded.
  Future<void> clear() async {
    _generation++;
    _pathsByUrl.clear();
    _inFlight.clear();
    final rootFuture = _rootFuture;
    _rootFuture = null;
    if (rootFuture == null) return;
    try {
      final root = await rootFuture;
      if (await root.exists()) await root.delete(recursive: true);
    } on Object catch (_) {
      // Best effort: the folder is swept again on the next run.
    }
  }

  Future<Directory> _prepareRoot() {
    return _rootFuture ??= () async {
      final root = await _rootProvider();
      if (!_staleSwept) {
        _staleSwept = true;
        try {
          if (await root.exists()) await root.delete(recursive: true);
        } on Object catch (_) {
          // A locked leftover file must not block this attempt's downloads.
        }
      }
      await root.create(recursive: true);
      return root;
    }();
  }

  Future<void> _download(String url, Directory root, int generation) {
    return _inFlight[url] ??= _downloadOnce(url, root, generation).whenComplete(
      () {
        _inFlight.remove(url);
      },
    );
  }

  Future<void> _downloadOnce(String url, Directory root, int generation) async {
    final target = p.join(root.path, '${_randomName()}${_extensionOf(url)}');
    try {
      await _dio.download(url, target);
      if (generation != _generation) {
        await _deleteQuietly(target);
        return;
      }
      _pathsByUrl[url] = target;
    } on Object catch (_) {
      await _deleteQuietly(target);
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on Object catch (_) {
      // Swept with the folder later.
    }
  }

  String _randomName() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  String _extensionOf(String url) {
    final ext = p.extension(Uri.tryParse(url)?.path ?? '').toLowerCase();
    return _knownExtensions.contains(ext) ? ext : '';
  }
}
