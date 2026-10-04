import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/analytics.dart';
import 'package:secure_by_design_app/data/learning_store.dart';

class FakeTransport implements AnalyticsTransport {
  final events = <Map<String, Object>>[];
  int cancellations = 0;
  bool fail = false;
  @override
  Future<void> send(Map<String, Object> event) async {
    if (fail) throw StateError('Offline');
    events.add(event);
  }
  @override
  void cancel() => cancellations++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default is off without an ID and learning still persists', () async {
    final transport = FakeTransport();
    final store = await LearningStore.load(transport: transport);
    store.analytics.appOpened();
    await store.completeLesson('ad-1');
    await store.toggleSaved('ms-ad');
    expect(transport.events, isEmpty);
    expect((await SharedPreferences.getInstance()).getString(
        LearningAnalytics.idKey), isNull);
    expect((await LearningStore.load()).completed, {'ad-1'});
  });

  test('consent persists, opt out cancels and re-enabling rotates ID', () async {
    final transport = FakeTransport();
    final store = await LearningStore.load(transport: transport);
    final analytics = store.analytics;
    await analytics.setEnabled(true);
    analytics.appOpened();
    final first = transport.events.single['distinct_id'];
    expect((await LearningStore.load()).analytics.enabled, isTrue);
    await analytics.setEnabled(false);
    analytics.appOpened();
    expect(transport.events, hasLength(1));
    expect(transport.cancellations, 1);
    expect((await SharedPreferences.getInstance()).getString(
        LearningAnalytics.idKey), isNull);
    expect((await LearningStore.load()).analytics.enabled, isFalse);
    await analytics.setEnabled(true);
    analytics.appOpened();
    expect(transport.events.last['distinct_id'], isNot(first));
  });

  test('only catalog IDs and fixed properties can leave the app', () async {
    final transport = FakeTransport();
    final store = await LearningStore.load(transport: transport);
    await store.analytics.setEnabled(true);
    store.analytics.lessonOpened('email@example.com');
    store.analytics.pathOpened('https://private.invalid');
    store.analytics.resourceOpened('private note');
    expect(transport.events, isEmpty);
    store.analytics.knowledgeCheckSubmitted('ad-1', false);
    final props = transport.events.single['properties'] as Map<String, Object>;
    expect(props['correct'], false);
    expect(props[r'$process_person_profile'], false);
    expect(props.keys.toSet(), {
      r'$process_person_profile', 'platform', 'environment', 'schema_version',
      'path_id', 'lesson_id', 'correct',
    });
  });

  test('completion emits once and bookmark removal emits no save', () async {
    final transport = FakeTransport();
    final store = await LearningStore.load(transport: transport);
    await store.analytics.setEnabled(true);
    await Future.wait([store.completeLesson('ad-1'), store.completeLesson('ad-1')]);
    await store.toggleSaved('ms-ad');
    await store.toggleSaved('ms-ad');
    expect(transport.events.map((e) => e['event']),
        ['lesson_completed', 'resource_saved']);
    expect((await LearningStore.load()).completed, {'ad-1'});
  });

  test('network failures cannot break a completed lesson', () async {
    final transport = FakeTransport()..fail = true;
    final store = await LearningStore.load(transport: transport);
    await store.analytics.setEnabled(true);
    await store.completeLesson('ad-1');
    await Future<void>.delayed(Duration.zero);
    expect((await LearningStore.load()).completed, {'ad-1'});
  });
}
