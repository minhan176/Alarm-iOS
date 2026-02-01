package com.oaptech.clock

import android.content.Intent
import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import android.provider.Settings
import android.net.Uri
import android.os.PowerManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oaptech.clock/navigation"
    private var binaryMessenger: io.flutter.plugin.common.BinaryMessenger? = null
    private var pendingAlarmJson: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        println("DEBUG: MainActivity onCreate called")

        // Set window flags to show over lock screen and other apps
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Check for alarm data from Intent (when started by alarm)
        val alarmJson = intent.getStringExtra("alarm_data")
        if (alarmJson != null) {
            println("DEBUG: Received alarm data from Intent: $alarmJson")
            // Store for navigation in configureFlutterEngine
            pendingAlarmJson = alarmJson
        } else {
            println("DEBUG: No alarm data in Intent")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        println("DEBUG: configureFlutterEngine called")

        // Store binary messenger for later use
        binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // Register alarm method channel directly
        val alarmChannel = MethodChannel(binaryMessenger!!, "com.oaptech.clock/alarm")
        val alarmPlugin = AlarmPlugin(this)
        alarmChannel.setMethodCallHandler(alarmPlugin)

        // Register timer ring method channel
        val timerRingChannel = MethodChannel(binaryMessenger!!, "com.oaptech.clock/timer_ring")
        timerRingChannel.setMethodCallHandler(alarmPlugin)

        // Register navigation method channel
        val navChannel = MethodChannel(binaryMessenger!!, CHANNEL)
        navChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "navigateToAlarm" -> {
                    // Navigate to alarm screen if needed
                    result.success(null)
                }
                "navigateToRingScreen" -> {
                    val alarmJson = call.arguments as? String
                    if (alarmJson != null) {
                        // Parse alarm and navigate to ring screen
                        // This will be handled in Flutter side
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Alarm data is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register battery optimization method channel
        val batteryChannel = MethodChannel(binaryMessenger!!, "com.oaptech.clock/battery")
        batteryChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.error("BATTERY_CHECK_ERROR", e.message, null)
                    }
                }
                "canRunInBackground" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.error("BACKGROUND_CHECK_ERROR", e.message, null)
                    }
                }
                "openBatterySettings" -> {
                    try {
                        // Open app-specific battery settings
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success("Opened app battery settings")
                    } catch (e: Exception) {
                        result.error("SETTINGS_OPEN_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Check for pending alarm when Flutter engine is ready
        if (pendingAlarmJson != null) {
            println("DEBUG: Navigating to ring screen with pending alarm: $pendingAlarmJson")
            try {
                val result = navChannel.invokeMethod("navigateToRingScreen", pendingAlarmJson)
                println("DEBUG: Method channel invokeMethod called successfully")
                pendingAlarmJson = null // Clear after use
            } catch (e: Exception) {
                println("DEBUG: Error calling method channel: ${e.message}")
            }
        } else {
            println("DEBUG: No pending alarm to navigate to")
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
