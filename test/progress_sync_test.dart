import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/account.dart';
import 'package:secure_by_design_app/data/learning_store.dart';

class Cloud implements AccountTransport {
  String user = 'alice';
  bool offline = false;
  Completer<Map<String, dynamic>>? delayed;
  final records = <String, Map<String, String>>{};
  final bookmarks = <String, Map<String, bool>>{};
  final activity = <String, Map<String, Map<String, Object>>>{};
  @override
  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, Object>? body, String? token}) async {
    if (path.endsWith('/signin')) {
      return {
        'token': List.filled(64, user == 'alice' ? 'a' : 'b').join(),
        'expiresAt':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'user': {'id': user, 'email': '$user@example.invalid'}
      };
    }
    if (path.endsWith('/signout')) return {'signedOut': true};
    if (offline) throw const AccountFailure('Offline');
    if (delayed != null) return delayed!.future;
    final owner = token!.startsWith('a') ? 'alice' : 'bob';
    if (path == '/api/native-activity') {
      final a = activity.putIfAbsent(owner, () => {});
      for (final row in body!['activity'] as List) {
        final event = Map<String, Object>.from(row as Map);
        a['${event['day']}|${event['lessonId']}'] = event;
      }
      return {
        'accountId': owner,
        'activity': a.values.toList(),
        'nextCursor': null
      };
    }
    final r = records.putIfAbsent(owner, () => {});
    final b = bookmarks.putIfAbsent(owner, () => {});
    for (final row in body!['records'] as List) {
      r[row['id'] as String] = row['status'] as String;
    }
    for (final row in body['bookmarks'] as List) {
      b[row['id'] as String] = row['saved'] as bool;
    }
    return {
      'accountId': owner,
      'records':
          r.entries.map((e) => {'id': e.key, 'status': e.value}).toList(),
      'bookmarks':
          b.entries.map((e) => {'id': e.key, 'saved': e.value}).toList()
    };
  }
}

Future<void> settled(LearningStore store) async {
  while (store.syncing) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('guest history is preserved and imports only when requested', () async {
    SharedPreferences.setMockInitialValues({
      'sbd.completed.v1': ['ad-1'],
      'sbd.saved.v1': ['journal', 'nist-rmf'],
      'sbd.lastPath.v1': 'ad'
    });
    final store = await LearningStore.load(), cloud = Cloud();
    final account = AccountStore(transport: cloud);
    addTearDown(store.dispose);
    addTearDown(account.dispose);
    expect(store.completed, {'ad-1'});
    expect(store.saved, contains('journal'));
    await account.signIn('alice@example.invalid', 'test');
    await store.connectAccount(account);
    expect(store.completed, isEmpty);
    expect(store.saved, isEmpty);
    expect(cloud.records['alice'], isEmpty);
    await store.importDeviceProgress();
    expect(cloud.records['alice']!['native:ad-1'], 'completed');
    expect(cloud.bookmarks['alice']!['journal'], true);
    await store.disconnectAccount();
    expect(store.completed, {'ad-1'});
    expect(store.saved, {'journal', 'nist-rmf'});
    expect(store.currentPath.id, 'ad');
  });
  test(
      'offline account changes survive restart and sync without touching guest data',
      () async {
    final cloud = Cloud();
    final auth = AccountStore(transport: cloud);
    addTearDown(auth.dispose);
    await auth.signIn('alice@example.invalid', 'test');
    final store = await LearningStore.load();
    await store.completeLesson('ad-2');
    await store.connectAccount(auth);
    cloud.offline = true;
    await store.completeLesson('training:identity-foundation:dc-prepare');
    await settled(store);
    await store.toggleSaved('dc-package');
    await settled(store);
    expect(store.syncError, isNotNull);
    store.dispose();
    final next = await LearningStore.load();
    addTearDown(next.dispose);
    expect(next.completed, {'ad-2'});
    await next.connectAccount(auth);
    expect(next.completed, {'training:identity-foundation:dc-prepare'});
    expect(next.saved, {'dc-package'});
    cloud.offline = false;
    await next.sync();
    expect(next.syncError, isNull);
    expect(next.stats.streak, 1);
    expect(cloud.activity['alice']!.length, 1);
    expect(cloud.records['alice']!['training:identity-foundation:dc-prepare'], 'completed');
    await next.toggleSaved('dc-package');
    await settled(next);
    expect(cloud.bookmarks['alice']!['dc-package'], false);
    await next.disconnectAccount();
    expect(next.completed, {'ad-2'});
  });
  test('course downloads the website catalogs sync with the account',
      () async {
    final cloud = Cloud();
    final auth = AccountStore(transport: cloud);
    addTearDown(auth.dispose);
    await auth.signIn('alice@example.invalid', 'test');
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    await store.connectAccount(auth);
    await store.toggleSaved('identity-foundation-package');
    await settled(store);
    await store.toggleSaved('identity-foundation-guide');
    await settled(store);
    expect(store.syncError, isNull);
    expect(cloud.bookmarks['alice']!['identity-foundation-guide'], true);
    expect(cloud.bookmarks['alice']!['identity-foundation-package'], true);
    expect(store.saved, {'identity-foundation-package', 'identity-foundation-guide'});
    await store.sync();
    expect(store.saved, {'identity-foundation-package', 'identity-foundation-guide'});
  });
  test('account switching and late responses never mix learner records',
      () async {
    final cloud = Cloud(), store = await LearningStore.load();
    final account = AccountStore(transport: cloud);
    addTearDown(account.dispose);
    addTearDown(store.dispose);
    await account.signIn('alice@example.invalid', 'test');
    await store.connectAccount(account);
    final late = Completer<Map<String, dynamic>>();
    cloud.delayed = late;
    final sync = store.sync();
    await store.disconnectAccount();
    cloud.delayed = null;
    cloud.user = 'bob';
    await account.signIn('bob@example.invalid', 'test');
    await store.connectAccount(account);
    late.complete({
      'accountId': 'alice',
      'records': [
        {'id': 'native:ad-1', 'status': 'completed'}
      ],
      'bookmarks': [
        {'id': 'dc-package', 'saved': true}
      ]
    });
    await sync;
    expect(store.accountScope, 'bob');
    expect(store.completed, isEmpty);
    expect(store.saved, isEmpty);
    expect(store.stats.totalXp, 0);
  });
  test('a response for another identity cannot replace cached progress',
      () async {
    final cloud = Cloud(), store = await LearningStore.load();
    final account = AccountStore(transport: cloud);
    addTearDown(account.dispose);
    addTearDown(store.dispose);
    await account.signIn('alice@example.invalid', 'test');
    await store.connectAccount(account);
    await store.completeLesson('ad-1');
    await settled(store);
    cloud.delayed = Completer<Map<String, dynamic>>()
      ..complete({'accountId': 'bob', 'records': [], 'bookmarks': []});
    await store.sync();
    expect(store.completed, {'ad-1'});
    expect(store.syncError, isNotNull);
  });
}
