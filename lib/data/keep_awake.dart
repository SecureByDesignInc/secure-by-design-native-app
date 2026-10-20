import 'package:flutter/services.dart';

/// Keeps the screen on while lab mode is open, so the phone can sit beside the
/// keyboard as a second screen. Implemented in ios/Runner/AppDelegate.swift
/// (the idle timer) and Android's MainActivity.kt (FLAG_KEEP_SCREEN_ON).
class KeepAwake {
  static const _channel = MethodChannel('com.securebydesigninc/keep_awake');

  static Future<void> set(bool on) async {
    try {
      await _channel.invokeMethod<void>('set', on);
    } on MissingPluginException {
      // Desktop builds and tests have no handler; the screen follows the system.
    } on PlatformException {
      // Not critical: lab mode works the same with the screen's own timeout.
    }
  }
}
