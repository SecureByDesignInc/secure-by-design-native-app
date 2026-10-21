import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/catalog_json.dart';
import 'package:secure_by_design_app/data/content_feed.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';

/// The shape the website publishes (scripts/prepare-app-content.mjs).
Map<String, Object> catalogJson({String title = 'Build and harden the identity foundation'}) => {
      'schema': 1,
      'categories': [
        {'id': 'network-build', 'title': 'Build the Network', 'description': 'Build it.'},
      ],
      'courses': [
        {
          'id': 'identity-foundation',
          'number': '1.1',
          'title': title,
          'subtitle': 'AD DS, DNS and time',
          'categoryId': 'network-build',
          'category': 'Network build',
          'description': 'Design the identity foundation.',
          'icon': 'directory',
          'published': true,
          'studyTime': '1 guided lesson · Self-paced',
          'topics': 1,
          'trailerYoutubeId': '',
          'materials': [
            {
              'id': 'identity-foundation-guide',
              'title': 'Interactive guide',
              'publisher': 'Secure By Design',
              'description': 'The guide.',
              'url': 'https://securebydesigninc.com/training/identity-foundation',
              'category': 'Training materials',
              'icon': 'directory',
              'syncable': true,
            },
          ],
          'lessons': [
            {
              'id': 'training:identity-foundation:dc-design',
              'title': 'Design the forest, domain and OUs',
              'minutes': 30,
              'summary': 'Decide the structure first.',
              'objectives': ['Explain the forest boundary.'],
              'recap': ['One forest.'],
              'next': 'Lesson 2.',
              'youtubeId': '',
              'sections': [
                {'heading': 'Step 1', 'body': 'Read the design reference.'},
                {'heading': 'Step 2', 'body': 'Write the decision.'},
                {'heading': 'Inspect your configuration', 'body': '# Check\nGet-ADForest'},
              ],
              'quizzes': [
                {
                  'question': 'Which is the security boundary?',
                  'answers': ['The domain', 'The forest'],
                  'correct': 1,
                  'explanation': 'The forest.',
                },
              ],
              'source': 'https://securebydesigninc.com/training/identity-foundation#dc-design',
              'guide': {
                'id': 'sbd-identity-foundation',
                'chapter': 'dc-design',
                'checklist': ['I wrote the decision.'],
                'stepTitles': ['Read the reference', 'Record the decision'],
              },
            },
          ],
        },
      ],
      'comingSoon': [
        {
          'id': 'endpoint-protection',
          'number': '1.9',
          'title': 'Endpoint protection on SBD-EPO01',
          'subtitle': '',
          'description': 'Coming soon.',
          'categoryId': 'network-build',
        },
      ],
    };

void main() {
  late Directory cache;
  setUp(() => cache = Directory.systemTemp.createTempSync('sbd-feed-test'));
  tearDown(() {
    useCatalog(bundledCatalog);
    cache.deleteSync(recursive: true);
  });

  test('the website catalog parses into courses, guides and coming-soon tiles', () {
    final catalog = parseCatalogJson(jsonDecode(jsonEncode(catalogJson())), version: 'abc');
    final lesson = catalog.paths.single.lessons.single;
    expect(catalog.paths.single.categoryId, 'network-build');
    expect(catalog.comingSoon.single.number, '1.9');
    expect(lesson.guide!.checkKey(0), 'dc-design-0');
    expect(lesson.labSteps.map((s) => s.title), ['Read the reference', 'Record the decision']);
    expect(lesson.labCommands, '# Check\nGet-ADForest');
  });

  test('a catalog with a bad link, quiz or schema is rejected whole', () {
    Map<String, dynamic> broken(void Function(Map<String, dynamic>) change) {
      final json = jsonDecode(jsonEncode(catalogJson())) as Map<String, dynamic>;
      change(json);
      return json;
    }

    for (final json in [
      broken((j) => j['schema'] = 2),
      broken((j) => j['courses'][0]['lessons'][0]['quizzes'][0]['correct'] = 5),
      broken((j) => j['courses'][0]['materials'][0]['url'] = 'http://example.com'),
      broken((j) => j['courses'][0]['categoryId'] = 'unknown'),
      broken((j) => j['courses'][0]['lessons'][0]['youtubeId'] = 'not a video id'),
    ]) {
      expect(() => parseCatalogJson(json, version: 'abc'), throwsFormatException);
    }
  });

  test('the bundled catalog is the website’s: categories, coming-soon tiles and guides', () {
    expect(bundledCatalogVersion, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(bundledCategories.map((c) => c.title), ['Build the Network', 'Network Authorization']);
    expect(bundledComingSoon.map((c) => c.number), ['1.9', '1.10']);
    for (final path in bundledPaths) {
      expect(bundledCategories.any((c) => c.contains(path)), isTrue, reason: path.id);
      if (path.categoryId == 'network-build') {
        for (final lesson in path.lessons) {
          expect(lesson.guide, isNotNull, reason: lesson.id);
          expect(lesson.labSteps, isNotEmpty, reason: lesson.id);
        }
      }
    }
  });

  group('content feed', () {
    late List<int> body;
    late Map<String, Object> manifest;
    late int downloads;
    late ContentFeed feed;
    setUp(() {
      body = utf8.encode(jsonEncode(catalogJson(title: 'Updated on the website')));
      final digest = sha256.convert(body).toString();
      manifest = {
        'schema': 1,
        'version': digest.substring(0, 16),
        'sha256': digest,
        'bytes': body.length,
        'url': '/app-content/v1/catalog.json',
      };
      downloads = 0;
      feed = ContentFeed(
          cache: cache,
          fetch: (url, maxBytes) async {
            if (url.path == ContentFeed.manifestPath) return utf8.encode(jsonEncode(manifest));
            downloads++;
            return body;
          });
    });

    test('a verified download is used from the next launch, and only once', () async {
      expect(await feed.refresh(), manifest['version']);
      expect(currentCatalog.version, bundledCatalogVersion);
      expect(await feed.refresh(), isNull);
      expect(downloads, 1);
      expect(await ContentFeed(cache: cache).applyCached(), isTrue);
      expect(currentCatalog.version, manifest['version']);
      expect(publishedPaths.single.title, 'Updated on the website');
    });

    test('a download whose hash or size differs is never stored', () async {
      manifest['sha256'] = '${manifest['version']}${'0' * 48}';
      expect(await feed.refresh(), isNull);
      manifest['sha256'] = sha256.convert(body).toString();
      manifest['bytes'] = body.length + 1;
      expect(await feed.refresh(), isNull);
      expect(await ContentFeed(cache: cache).applyCached(), isFalse);
    });

    test('a newer schema waits for an app update', () async {
      manifest['schema'] = 2;
      expect(await feed.refresh(), isNull);
      expect(downloads, 0);
    });

    test('a damaged cache, or one an older release saved, falls back to the bundled catalog', () async {
      expect(await feed.refresh(), isNotNull);
      final file = File('${cache.path}${Platform.pathSeparator}catalog.json');
      file.writeAsStringSync('{"schema":1}');
      expect(await ContentFeed(cache: cache).applyCached(), isFalse);
      expect(currentCatalog.version, bundledCatalogVersion);

      expect(await feed.refresh(), isNotNull);
      final record = File('${cache.path}${Platform.pathSeparator}catalog-record.json');
      final saved = jsonDecode(record.readAsStringSync()) as Map<String, dynamic>;
      record.writeAsStringSync(jsonEncode({...saved, 'bundled': '0000000000000000'}));
      expect(await ContentFeed(cache: cache).applyCached(), isFalse);
      expect(currentCatalog.version, bundledCatalogVersion);
    });

    test('offline, the app keeps its catalog', () async {
      final offline = ContentFeed(
          cache: cache, fetch: (url, maxBytes) async => throw const SocketException('offline'));
      expect(await offline.refresh(), isNull);
      expect(await offline.applyCached(), isFalse);
    });
  });
}
