package com.nacho.gider

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val secureChannelName = "com.nacho.gider/window_secure"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Default to secure so the very first recents snapshot after install
        // (before Dart has a chance to sync app-lock state) is never a plain
        // capture of the dashboard. Dart clears the flag only when app lock
        // is disabled.
        applySecureFlag(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val secure = call.argument<Boolean>("secure") ?: true
                    runOnUiThread { applySecureFlag(secure) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun applySecureFlag(secure: Boolean) {
        if (secure) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
