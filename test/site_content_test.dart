import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/catalog.dart';
import 'package:secure_by_design_app/data/models.dart';
import 'package:secure_by_design_app/data/published_catalog.dart';
import 'package:secure_by_design_app/data/site_content.dart';
import 'package:secure_by_design_app/data/training_categories.dart';

void main() {
  final bundledJson = File(SiteContent.bundledAsset).readAsStringSync();
  Map<String, dynamic> feed() =>
      jsonDecode(bundledJson) as Map<String, dynamic>;

  tearDown(() => SiteContent.instance.loadBundledForTesting(bundledJson));

  test('the bundled copy is the website feed the app reads', () {
    final data = SiteContent.parse(bundledJson);
    expect(feed()['schema'], SiteContent.schema);
    expect(data.version, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(data.paths.length, 13);
    expect(data.paths.every((path) => path.published), isTrue);
    expect(data.network['nodes'], isNotEmpty);
    expect(publishedPaths.map((p) => p.id), data.paths.map((p) => p.id));
  });

  test('every lesson keeps all of its knowledge checks in order', () {
    final json = feed();
    final data = SiteContent.parse(bundledJson);
    final courses = json['courses'] as List;
    for (var c = 0; c < courses.length; c++) {
      final lessons = (courses[c] as Map)['lessons'] as List;
      for (var l = 0; l < lessons.length; l++) {
        final quizzes = (lessons[l] as Map)['quizzes'] as List;
        final lesson = data.paths[c].lessons[l];
        expect(lesson.questions.length, quizzes.length, reason: lesson.id);
        expect(lesson.questions.first.question, (quizzes.first as Map)['question']);
      }
    }
  });

  test('content this app cannot show is rejected, never half-applied', () {
    expect(() => SiteContent.parse('not json'), throwsFormatException);
    expect(() => SiteContent.parse(jsonEncode({...feed(), 'schema': 2})),
        throwsFormatException);
    expect(() => SiteContent.parse(jsonEncode({...feed(), 'courses': []})),
        throwsFormatException);

    final badAnswer = feed();
    final lesson = (((badAnswer['courses'] as List).first as Map)['lessons']
        as List).first as Map;
    ((lesson['quizzes'] as List).first as Map)['correct'] = 99;
    expect(() => SiteContent.parse(jsonEncode(badAnswer)), throwsFormatException);

    final repeated = feed();
    final courses = repeated['courses'] as List;
    courses.add(courses.first);
    expect(() => SiteContent.parse(jsonEncode(repeated)), throwsFormatException);
  });

  test('a website update replaces the catalog, keeping progress for shipped lessons', () {
    final json = feed();
    final courses = json['courses'] as List;
    final removed = courses.removeLast() as Map<String, dynamic>;
    final added = Map<String, dynamic>.from(courses.first as Map)
      ..['id'] = 'new-course'
      ..['number'] = '1.11'
      ..['lessons'] = [
        {
          ...((courses.first as Map)['lessons'] as List).first as Map,
          'id': 'training:new-course:first',
        }
      ];
    courses.add(added);
    json['version'] = '0123456789abcdef';

    SiteContent.instance.loadBundledForTesting(bundledJson);
    final shipped = SiteContent.instance.knownLessonIds;
    final update = SiteContent.parse(jsonEncode(json));
    expect(update.paths.map((p) => p.id), contains('new-course'));
    expect(update.paths.map((p) => p.id), isNot(contains(removed['id'])));
    // Every lesson this build shipped with stays known after any update.
    expect(shipped, containsAll(
        ((removed['lessons'] as List).map((l) => (l as Map)['id']))));
    expect(learningPaths.length, publishedPaths.length + foundationPaths.length);
  });

  test('courses the website adds later are still listed in the Training Library', () {
    LearningPath course(String id, String category) => LearningPath(
        id: id,
        title: id,
        category: category,
        description: '',
        icon: 'directory',
        lessons: const []);
    final build = course('future-build-course', 'Network build');
    final authorize = course('future-authorization', 'Network authorization');
    final other = course('future-cloud', 'Cloud security');
    expect(categoryFor(build).id, 'foundations');
    expect(categoryFor(authorize).id, 'authorization');
    expect(categoryFor(other).title, 'Cloud security');
    final groups = categoriesFor([...publishedPaths, build, authorize, other]);
    expect(groups.map((g) => g.id),
        [...trainingCategories.map((g) => g.id), 'Cloud security']);
    for (final path in [...publishedPaths, build, authorize, other]) {
      expect(groups.where((g) => inCategory(path, g)).length, 1, reason: path.id);
    }
  });
}
