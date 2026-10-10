import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Where the content on screen came from.
enum ContentSource { bundled, downloaded }

/// One parsed copy of the website's training content feed.
class SiteContentData {
  const SiteContentData(this.version, this.paths, this.network);
  final String version;
  final List<LearningPath> paths;

  /// The Inside the Network reference (systems, traffic processes, policy).
  final Map<String, dynamic> network;
  Set<String> get lessonIds =>
      {for (final path in paths) for (final lesson in path.lessons) lesson.id};
}

/// The published Training Library courses and the Inside the Network
/// reference, kept in step with the website.
///
/// The website builds its feed at [endpoint] on every deploy
/// (scripts/prepare-app-content.mjs in the website repository). The app shows
/// the last good download, or the copy bundled at build time, and checks for a
/// newer version on launch and whenever it returns to the foreground. A valid
/// new version is saved and shown straight away; anything that fails to
/// download or parse is ignored, so the app never loses its content.
class SiteContent extends ChangeNotifier {
  SiteContent._();
  static final instance = SiteContent._();

  /// The feed shape this app reads. The website only changes it together with
  /// an app release; until then this app keeps its own content.
  static const schema = 1;
  static const bundledAsset = 'assets/training/content.json';
  static final endpoint =
      Uri.parse('https://securebydesigninc.com/app/content/v1.json');

  static const _etagKey = 'sbd.siteContent.etag.v1';
  static const _cachedWithKey = 'sbd.siteContent.cachedWith.v1';
  static const _cacheName = 'site-content-v1.json';

  SiteContentData? _data;
  Set<String> _bundledLessonIds = const {};
  String _bundledVersion = '';
  ContentSource _source = ContentSource.bundled;
  Future<bool>? _refreshing;

  /// Widget tests and other test runs never reach the network or the disk.
  static final bool _remoteEnabled =
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  SiteContentData get _current =>
      _data ??
      (throw StateError(
          'SiteContent.load() must finish before the catalog is read.'));
  bool get isLoaded => _data != null;
  List<LearningPath> get paths => _current.paths;
  Map<String, dynamic> get network => _current.network;
  String get version => _current.version;
  String get bundledVersion => _bundledVersion;
  ContentSource get source => _source;

  /// Lessons whose saved progress is kept: everything shown now plus
  /// everything this build shipped with, so a lesson missing from one download
  /// never erases a learner's progress.
  Set<String> get knownLessonIds => {..._bundledLessonIds, ..._current.lessonIds};

  /// Reads the bundled copy, then the last good download if it is newer than
  /// this build. Call once before the learning store loads.
  Future<void> load() async {
    if (isLoaded) return;
    // Decode on this isolate; the feed is small enough not to need another.
    final bytes = await rootBundle.load(bundledAsset);
    final bundled = parse(utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)));
    _useBundled(bundled);
    if (!_remoteEnabled) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final file = await _cacheFile();
      // A download made before this build was installed is older than the
      // content the build shipped with; the launch check fetches the latest.
      if (preferences.getString(_cachedWithKey) != bundled.version) {
        await _discardCache(preferences, file);
        return;
      }
      if (await file.exists()) {
        _data = parse(await file.readAsString());
        _source = ContentSource.downloaded;
      }
    } catch (_) {
      // A damaged or unreadable download: keep the bundled content.
      _data = bundled;
      _source = ContentSource.bundled;
    }
  }

  /// Checks the website for newer content. Returns true when new content was
  /// applied. Safe to call often: concurrent calls share one request, and an
  /// unchanged feed answers 304 Not Modified.
  Future<bool> refresh() {
    if (!_remoteEnabled || !isLoaded) return Future.value(false);
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _refresh() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final preferences = await SharedPreferences.getInstance();
      final request = await client.getUrl(endpoint);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final etag = preferences.getString(_etagKey);
      // Only a saved download can be revalidated; the bundled copy has no ETag.
      if (etag != null && _source == ContentSource.downloaded) {
        request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return false;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final data = parse(body);
      final newEtag = response.headers.value(HttpHeaders.etagHeader);
      if (data.version == version) {
        if (_source == ContentSource.downloaded && newEtag != null) {
          await preferences.setString(_etagKey, newEtag);
        }
        return false;
      }
      final file = await _cacheFile();
      final partial = File('${file.path}.download');
      await partial.writeAsString(body, flush: true);
      await partial.rename(file.path);
      await preferences.setString(_cachedWithKey, _bundledVersion);
      if (newEtag != null) {
        await preferences.setString(_etagKey, newEtag);
      } else {
        await preferences.remove(_etagKey);
      }
      _data = data;
      _source = ContentSource.downloaded;
      notifyListeners();
      return true;
    } catch (_) {
      // Offline, slow, or an unexpected feed: keep what is on screen.
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Uses [json] as this build's bundled content. Tests call this before any
  /// catalog read (see test/flutter_test_config.dart).
  @visibleForTesting
  void loadBundledForTesting(String json) => _useBundled(parse(json));

  void _useBundled(SiteContentData bundled) {
    _bundledVersion = bundled.version;
    _bundledLessonIds = bundled.lessonIds;
    _data = bundled;
    _source = ContentSource.bundled;
  }

  Future<File> _cacheFile() async =>
      File('${(await getApplicationSupportDirectory()).path}/$_cacheName');

  Future<void> _discardCache(SharedPreferences preferences, File file) async {
    await preferences.remove(_etagKey);
    await preferences.remove(_cachedWithKey);
    if (await file.exists()) await file.delete();
  }

  /// Parses and validates one copy of the feed. Throws [FormatException] for
  /// anything this app can't show correctly.
  static SiteContentData parse(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('The content feed is not an object.');
      }
      if (json['schema'] != schema) {
        throw FormatException('Unsupported content schema ${json['schema']}.');
      }
      final paths = List<LearningPath>.unmodifiable(
          _list(json, 'courses').map((c) => _path(_map(c))));
      if (paths.isEmpty) {
        throw const FormatException('The content feed has no courses.');
      }
      final pathIds = paths.map((p) => p.id).toList();
      final lessonIds = [
        for (final path in paths) for (final lesson in path.lessons) lesson.id
      ];
      if (pathIds.toSet().length != pathIds.length ||
          lessonIds.toSet().length != lessonIds.length) {
        throw const FormatException('Course or lesson IDs repeat.');
      }
      final network = Map<String, dynamic>.unmodifiable(_map(json['network']));
      if (network['nodes'] is! List || network['scenarios'] is! List) {
        throw const FormatException('The network reference is incomplete.');
      }
      return SiteContentData(_text(json, 'version'), paths, network);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid content feed: $error');
    }
  }

  static LearningPath _path(Map<String, dynamic> json) {
    final lessons = _list(json, 'lessons').map((l) => _lesson(_map(l))).toList();
    if (lessons.isEmpty) {
      throw FormatException('Course ${json['id']} has no lessons.');
    }
    return LearningPath(
      id: _text(json, 'id'),
      number: _text(json, 'number', fallback: ''),
      title: _text(json, 'title'),
      subtitle: _text(json, 'subtitle', fallback: ''),
      category: _text(json, 'category'),
      description: _text(json, 'description', fallback: ''),
      icon: _text(json, 'icon', fallback: 'directory'),
      published: true,
      studyTime: _text(json, 'studyTime', fallback: ''),
      topics: _int(json, 'topics', fallback: lessons.length),
      materials: List.unmodifiable(
          _list(json, 'materials').map((m) => _material(_map(m)))),
      lessons: List.unmodifiable(lessons),
    );
  }

  static Lesson _lesson(Map<String, dynamic> json) {
    final quizzes =
        _list(json, 'quizzes').map((q) => _quiz(_map(q))).toList();
    if (quizzes.isEmpty) {
      throw FormatException('Lesson ${json['id']} has no knowledge check.');
    }
    final first = quizzes.first;
    return Lesson(
      id: _text(json, 'id'),
      title: _text(json, 'title'),
      minutes: _int(json, 'minutes'),
      summary: _text(json, 'summary', fallback: ''),
      objectives: _strings(json, 'objectives'),
      sections: List.unmodifiable(_list(json, 'sections').map((s) {
        final section = _map(s);
        return LessonSection(_text(section, 'heading'), _text(section, 'body'));
      })),
      question: first.question,
      answers: first.answers,
      correctAnswer: first.correctAnswer,
      explanation: first.explanation,
      moreQuestions: List.unmodifiable(quizzes.skip(1)),
      recap: _strings(json, 'recap'),
      nextStep: _text(json, 'next', fallback: ''),
      sourceUrl: _text(json, 'sourceUrl'),
      sourceLabel: _text(json, 'sourceLabel', fallback: 'Open the complete guide'),
      youtubeId: _text(json, 'youtubeId', fallback: ''),
    );
  }

  static QuizQuestion _quiz(Map<String, dynamic> json) {
    final answers = _strings(json, 'answers');
    final correct = _int(json, 'correct');
    if (correct < 0 || correct >= answers.length) {
      throw FormatException('Invalid answer for "${json['question']}".');
    }
    return QuizQuestion(_text(json, 'question'), answers, correct,
        _text(json, 'explanation', fallback: ''));
  }

  static LearningResource _material(Map<String, dynamic> json) =>
      LearningResource(
        id: _text(json, 'id'),
        title: _text(json, 'title'),
        publisher: _text(json, 'publisher', fallback: 'Secure By Design'),
        description: _text(json, 'description', fallback: ''),
        url: _text(json, 'url'),
        category: _text(json, 'category', fallback: 'Training materials'),
        icon: _text(json, 'icon', fallback: 'directory'),
        syncable: json['syncable'] != false,
      );

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Expected an object, found $value.');
  }

  static List<Object?> _list(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) return value;
    throw FormatException('Expected a list for $key.');
  }

  static List<String> _strings(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is List && value.every((item) => item is String)) {
      return List.unmodifiable(value.cast<String>());
    }
    throw FormatException('Expected a list of text for $key.');
  }

  static String _text(Map<String, dynamic> json, String key,
      {String? fallback}) {
    final value = json[key];
    if (value is String) return value;
    if (value == null && fallback != null) return fallback;
    throw FormatException('Expected text for $key.');
  }

  static int _int(Map<String, dynamic> json, String key, {int? fallback}) {
    final value = json[key];
    if (value is int) return value;
    if (value == null && fallback != null) return fallback;
    throw FormatException('Expected a whole number for $key.');
  }
}
