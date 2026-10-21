package com.securebydesigninc.secure_by_design_app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lab mode keeps the screen on while a learner follows the steps (lib/data/keep_awake.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.securebydesigninc/keep_awake")
            .setMethodCallHandler { call, result ->
                val on = call.arguments as? Boolean
                if (call.method != "set" || on == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (on) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            }
    }
}
