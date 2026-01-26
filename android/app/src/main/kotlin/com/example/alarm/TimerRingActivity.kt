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

class TimerRingActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm/timer_ring"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        println("DEBUG: TimerRingActivity onCreate called")

        // Set window flags to show over lock screen and other apps
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON)

        // Get timer data from intent
        val remainingSeconds = intent.getIntExtra("remaining_seconds", 0)
        val selectedSound = intent.getStringExtra("selected_sound") ?: "Radar"
        val selectedVibrate = intent.getBooleanExtra("selected_vibrate", false)
        println("DEBUG: TimerRingActivity remainingSeconds=$remainingSeconds, selectedSound=$selectedSound, selectedVibrate=$selectedVibrate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        println("DEBUG: TimerRingActivity configureFlutterEngine called")

        // Register alarm method channel (same as MainActivity)
        val alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.alarm/alarm")
        val alarmPlugin = AlarmPlugin(this)
        alarmChannel.setMethodCallHandler(alarmPlugin)

        // Set up method channel to pass timer data to Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTimerData" -> {
                        val remainingSeconds = intent.getIntExtra("remaining_seconds", 0)
                        val selectedSound = intent.getStringExtra("selected_sound") ?: "Radar"
                        val selectedVibrate = intent.getBooleanExtra("selected_vibrate", false)
                        val timerData = mapOf(
                            "remainingSeconds" to remainingSeconds,
                            "selectedSound" to selectedSound,
                            "selectedVibrate" to selectedVibrate
                        )
                        result.success(timerData)
                    }
                    "stopTimer" -> {
                        // Close the activity when timer is stopped
                        println("DEBUG: TimerRingActivity stopTimer called, finishing activity")
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
        println("DEBUG: TimerRingActivity onNewIntent called, finishing activity")
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        println("DEBUG: TimerRingActivity onDestroy called")
    }

    // Override to specify the Flutter route for this activity
    override fun getInitialRoute(): String {
        return "/timer_ring"
    }
}