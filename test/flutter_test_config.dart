import 'dart:async';
import 'dart:io';

import 'package:secure_by_design_app/data/site_content.dart';

/// Runs before every test file: the app reads its courses from the bundled
/// website content, which the app itself loads during startup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SiteContent.instance.loadBundledForTesting(
      File(SiteContent.bundledAsset).readAsStringSync());
  await testMain();
}
