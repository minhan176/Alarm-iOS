package com.example.alarm

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmRingActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm/ring"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        println("DEBUG: AlarmRingActivity onCreate called")

        // Set window flags to show over lock screen and other apps
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON)

        // Get alarm data from intent
        val alarmJson = intent.getStringExtra("alarm_data")
        if (alarmJson != null) {
            println("DEBUG: AlarmRingActivity received alarm data: $alarmJson")
        } else {
            println("DEBUG: AlarmRingActivity no alarm data received")
            finish() // Close if no alarm data
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        println("DEBUG: AlarmRingActivity configureFlutterEngine called")

        // Register alarm method channel (same as MainActivity)
        val alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.alarm/alarm")
        val alarmPlugin = AlarmPlugin(this)
        alarmChannel.setMethodCallHandler(alarmPlugin)

        // Set up method channel to pass alarm data to Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAlarmData" -> {
                        val alarmJson = intent.getStringExtra("alarm_data")
                        result.success(alarmJson)
                    }
                    "dismissAlarm" -> {
                        // Close the activity when alarm is dismissed
                        println("DEBUG: AlarmRingActivity dismissAlarm called, finishing activity")
                        finish()
                        result.success(null)
                    }
                    "snoozeAlarm" -> {
                        // Close the activity when alarm is snoozed
                        println("DEBUG: AlarmRingActivity snoozeAlarm called, finishing activity")
                        finish()
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // If activity is reopened, finish it immediately
        println("DEBUG: AlarmRingActivity onNewIntent called, finishing activity")
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        println("DEBUG: AlarmRingActivity onDestroy called")
    }

    // Override to specify the Flutter route for this activity
    override fun getInitialRoute(): String {
        return "/alarm_ring"
    }
}