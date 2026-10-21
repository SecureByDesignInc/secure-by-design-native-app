import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'catalog.dart';
import 'catalog_json.dart';
import 'published_catalog.dart';

/// Fetches [url] and returns its body, refusing anything over [maxBytes].
typedef FeedFetcher = Future<List<int>> Function(Uri url, int maxBytes);

/// Keeps the app's training catalog in step with the website without a new
/// App Store or Google Play build.
///
/// The website publishes the catalog at /app-content/v1/ with a manifest that
/// names its SHA-256. [refresh] downloads a changed catalog in the background,
/// checks the hash and that every course parses, and stores it; [applyCached]
/// uses it from the next launch, so lessons never change while one is open.
/// The catalog is content (text, quizzes, links and video IDs), never code.
/// Anything unexpected leaves the catalog built into this release in place.
class ContentFeed {
  ContentFeed({Directory? cache, FeedFetcher? fetch})
      : _cache = cache ??
            Directory('${Directory.systemTemp.path}${Platform.pathSeparator}sbd-content'),
        _fetch = fetch ?? _httpFetch;

  static const host = 'securebydesigninc.com';
  static const manifestPath = '/app-content/v1/manifest.json';
  static const maxCatalogBytes = 8 * 1024 * 1024;

  /// The download is a cache: if the system clears it, the app uses the
  /// catalog it shipped with and downloads the current one again.
  final Directory _cache;
  final FeedFetcher _fetch;

  File get _catalogFile =>
      File('${_cache.path}${Platform.pathSeparator}catalog.json');
  File get _recordFile =>
      File('${_cache.path}${Platform.pathSeparator}catalog-record.json');

  static final _hex16 = RegExp(r'^[0-9a-f]{16}$');
  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Uses the catalog an earlier launch downloaded, if it is intact and was
  /// downloaded by this release. Returns whether it did.
  Future<bool> applyCached() async {
    try {
      if (!await _recordFile.exists() || !await _catalogFile.exists()) {
        return false;
      }
      final record = jsonDecode(await _recordFile.readAsString());
      if (record is! Map<String, dynamic>) return false;
      final version = record['version'], digest = record['sha256'];
      // A newer app release ships a newer catalog of its own: a download made
      // by an older release is discarded rather than allowed to replace it.
      if (record['bundled'] != bundledCatalogVersion ||
          version is! String ||
          digest is! String ||
          !_hex16.hasMatch(version) ||
          !_hex64.hasMatch(digest)) {
        await _clear();
        return false;
      }
      final bytes = await _catalogFile.readAsBytes();
      if (sha256.convert(bytes).toString() != digest) {
        await _clear();
        return false;
      }
      useCatalog(parseCatalogJson(jsonDecode(utf8.decode(bytes)), version: version));
      return true;
    } catch (_) {
      await _clear();
      return false;
    }
  }

  /// Checks the website for a newer catalog and keeps it for the next launch.
  /// Returns the version it stored, or null when nothing changed or the check
  /// failed (offline, a damaged download, or a schema this release can't read).
  Future<String?> refresh() async {
    try {
      final manifest = jsonDecode(utf8.decode(
          await _fetch(Uri.https(host, manifestPath), 16384)));
      if (manifest is! Map<String, dynamic>) return null;
      final version = manifest['version'],
          digest = manifest['sha256'],
          size = manifest['bytes'],
          url = manifest['url'];
      if (manifest['schema'] != bundledCatalogSchema ||
          version is! String ||
          digest is! String ||
          size is! int ||
          url is! String ||
          !_hex16.hasMatch(version) ||
          !_hex64.hasMatch(digest) ||
          !digest.startsWith(version) ||
          size <= 0 ||
          size > maxCatalogBytes ||
          !url.startsWith('/app-content/v1/')) {
        return null;
      }
      if (version == currentCatalog.version || version == await _storedVersion()) {
        return null;
      }
      final bytes = await _fetch(Uri.https(host, url), size);
      if (bytes.length != size || sha256.convert(bytes).toString() != digest) {
        return null;
      }
      // Parse before storing, so a catalog this release can't read never replaces one it can.
      parseCatalogJson(jsonDecode(utf8.decode(bytes)), version: version);
      await _cache.create(recursive: true);
      final partial = File('${_catalogFile.path}.partial');
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(_catalogFile.path);
      await _recordFile.writeAsString(jsonEncode(
          {'version': version, 'sha256': digest, 'bundled': bundledCatalogVersion}),
          flush: true);
      return version;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _storedVersion() async {
    try {
      final record = jsonDecode(await _recordFile.readAsString());
      return record is Map<String, dynamic> && record['bundled'] == bundledCatalogVersion
          ? record['version'] as String?
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clear() async {
    for (final file in [_recordFile, _catalogFile]) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        // A cache that can't be removed is ignored on the next launch.
      }
    }
  }
}

Future<List<int>> _httpFetch(Uri url, int maxBytes) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(url);
    request.followRedirects = false;
    request.headers.set('x-sbd-client', 'native-v1');
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw HttpException('Status ${response.statusCode}', uri: url);
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 60))) {
      if (bytes.length + chunk.length > maxBytes) {
        throw HttpException('Response too large', uri: url);
      }
      bytes.addAll(chunk);
    }
    return bytes;
  } finally {
    client.close(force: true);
  }
}
