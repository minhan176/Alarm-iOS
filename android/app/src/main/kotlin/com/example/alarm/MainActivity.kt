package com.example.alarm

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm/navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the alarm plugin
        flutterEngine.plugins.add(AlarmPlugin())

        // Set up method channel for navigation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "navigateToAlarm") {
                    // Navigate to alarm screen if needed
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle alarm icon tap
        val alarmId = intent.getIntExtra("alarm_id", -1)
        if (alarmId != -1) {
            // User tapped on system alarm icon
            // You can handle navigation here if needed
        }
    }
}
