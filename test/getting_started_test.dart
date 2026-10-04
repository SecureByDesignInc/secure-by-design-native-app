import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/getting_started.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('0/3/7-day cards appear once and survive app restarts', () async {
    var now = DateTime.utc(2026, 10, 4);
    final prefs = await SharedPreferences.getInstance();
    final store = GettingStartedStore(prefs, now: () => now);
    addTearDown(store.dispose);
    await store.initialize();
    expect(store.next, GettingStartedMessage.welcome);
    await store.dismiss(GettingStartedMessage.welcome);
    expect(store.next, null);
    now = now.add(const Duration(days: 3) - const Duration(seconds: 1));
    expect(store.next, null);
    now = now.add(const Duration(seconds: 1));
    expect(store.next, GettingStartedMessage.resources);
    await store.dismiss(GettingStartedMessage.resources);
    final reloaded = GettingStartedStore(prefs, now: () => now);
    addTearDown(reloaded.dispose);
    await reloaded.initialize();
    expect(reloaded.next, null);
    now = now.add(const Duration(days: 4));
    expect(reloaded.next, GettingStartedMessage.feedback);
    await reloaded.dismiss(GettingStartedMessage.feedback);
    now = now.add(const Duration(days: 365));
    expect(reloaded.next, null);
  });

  test('turning prompts off persists without resetting dismissals or timing',
      () async {
    var now = DateTime.utc(2026, 10, 4);
    final prefs = await SharedPreferences.getInstance();
    final store = GettingStartedStore(prefs, now: () => now);
    addTearDown(store.dispose);
    await store.initialize();
    await store.dismiss(GettingStartedMessage.welcome);
    await store.setEnabled(false);
    now = now.add(const Duration(days: 8));
    final reloaded = GettingStartedStore(prefs, now: () => now);
    addTearDown(reloaded.dispose);
    expect(reloaded.enabled, false);
    expect(reloaded.next, null);
    await reloaded.setEnabled(true);
    expect(reloaded.next, GettingStartedMessage.resources);
    await reloaded.dismiss(GettingStartedMessage.resources);
    expect(reloaded.next, GettingStartedMessage.feedback);
  });

  test('moving the clock backwards does not release future tips', () async {
    var now = DateTime.utc(2026, 10, 4);
    final store = GettingStartedStore(await SharedPreferences.getInstance(),
        now: () => now);
    addTearDown(store.dispose);
    await store.initialize();
    await store.dismiss(GettingStartedMessage.welcome);
    now = now.subtract(const Duration(days: 20));
    expect(store.next, null);
  });
}
