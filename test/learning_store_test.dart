import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'completion and bookmarks survive loading another app session',
    () async {
      final store = await LearningStore.load();
      await store.completeLesson('ad-1');
      await store.completeLesson('ad-1');
      await store.toggleSaved('nist-rmf');
      await store.openPath('rmf');
      final reloaded = await LearningStore.load();
      expect(reloaded.completed, {'ad-1'});
      expect(reloaded.saved, {'nist-rmf'});
      expect(reloaded.currentPath.id, 'rmf');
      expect(reloaded.completedIn(foundationPaths.first), 1);
      expect(reloaded.nextLesson(foundationPaths.first)?.id, 'ad-2');
    },
  );

  test('a completed path has no unfinished next lesson', () async {
    final store = await LearningStore.load();
    for (final lesson in learningPaths.first.lessons) {
      await store.completeLesson(lesson.id);
    }
    expect(store.progressIn(learningPaths.first), 1);
    expect(store.nextLesson(learningPaths.first), isNull);
  });

  test(
    'serial actions preserve all writes and a bookmark can be removed',
    () async {
      final store = await LearningStore.load();
      await Future.wait([
        store.completeLesson('ad-1'),
        store.completeLesson('rmf-1'),
        store.toggleSaved('nist-rmf'),
      ]);
      await store.toggleSaved('nist-rmf');
      final reloaded = await LearningStore.load();
      expect(reloaded.completed, {'ad-1', 'rmf-1'});
      expect(reloaded.saved, isEmpty);
    },
  );

  test(
    'unknown saved IDs are ignored and invalid writes are rejected',
    () async {
      SharedPreferences.setMockInitialValues({
        'sbd.completed.v1': ['unknown', 'ad-1'],
        'sbd.saved.v1': ['removed'],
        'sbd.lastPath.v1': 'removed',
      });
      final store = await LearningStore.load();
      expect(store.completed, {'ad-1'});
      expect(store.saved, isEmpty);
      expect(store.currentPath.id, 'dc01-dc02');
      await expectLater(store.completeLesson('missing'), throwsArgumentError);
      await expectLater(store.toggleSaved('missing'), throwsArgumentError);
    },
  );

  test(
    'device progress follows lessons moved by the October 2026 restructure',
    () async {
      SharedPreferences.setMockInitialValues({
        'sbd.completed.v1': [
          'training:connect-segment:time',
          'training:connect-segment:router',
          'training:pki-services:template-admin',
          'training:harden-baseline:staging',
          'training:patch-protect:epo',
        ],
        'sbd.started.v1': ['training:pki-services:validate'],
        'sbd.lastPath.v1': 'pki-services',
      });
      final store = await LearningStore.load();
      expect(store.completed, {
        'training:domain-time:time',
        'training:two-tier-pki:template-admin',
        'training:stig-scap:staging',
      });
      expect(store.currentPath.id, 'two-tier-pki');
    },
  );
}
