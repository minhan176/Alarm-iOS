package com.oaptech.clock

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.os.Vibrator
import android.content.Context
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.VibrationEffect
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AlarmRingActivity : FlutterActivity() {
    private val CHANNEL = "com.oaptech.clock/ring"
    private var isDismissed = false
    private lateinit var screenOffReceiver: BroadcastReceiver

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        println("DEBUG: AlarmRingActivity onCreate called")

        // Set window flags to show over lock screen and other apps
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON)

        // Register receiver for screen off
        screenOffReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    println("DEBUG: Screen off detected, finishing activity")
                    finish()
                }
            }
        }
        registerReceiver(screenOffReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))

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
        val alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.oaptech.clock/alarm")
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
                        isDismissed = true
                        finish()
                        result.success(null)
                    }
                    "snoozeAlarm" -> {
                        // Close the activity when alarm is snoozed
                        println("DEBUG: AlarmRingActivity snoozeAlarm called, finishing activity")
                        isDismissed = true
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

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_MUTE -> {
                println("DEBUG: Volume button pressed, snoozing and finishing activity")
                finish()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onPause() {
        super.onPause()
        // When user presses home button, activity goes to background
        if (!isDismissed && !isFinishing) {
            println("DEBUG: Activity paused (home button pressed), finishing activity for snooze")
            finish()
        }
    }

    override fun onDestroy() {
        // Unregister receiver
        unregisterReceiver(screenOffReceiver)
        
        if (!isDismissed) {
            // Snooze and cancel the alarm when activity is destroyed without user action
            println("DEBUG: Snoozing and cancelling alarm because activity destroyed without user action")
            snoozeAlarm()
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null) {
                // Try multiple cancel methods
                vibrator.cancel()
                // For Android O+, try to vibrate with 0 amplitude to stop
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createOneShot(1, 0))
                }
                println("DEBUG: Force cancelled vibration with native vibrator")
            }
        }
        
        
        super.onDestroy()
        println("DEBUG: AlarmRingActivity onDestroy called")
        
        
    }

    // Override to specify the Flutter route for this activity
    override fun getInitialRoute(): String {
        return "/alarm_ring"
    }

    private fun snoozeAlarm() {
        try {
            val alarmJson = intent.getStringExtra("alarm_data")
            if (alarmJson != null) {
                val alarmObj = JSONObject(alarmJson)
                val snoozeMinutes = alarmObj.optInt("snoozeDuration", 5) // Default 5 minutes
                
                val snoozeTime = System.currentTimeMillis() + (snoozeMinutes * 60 * 1000)
                
                val intent = Intent(this, AlarmReceiver::class.java).apply {
                    putExtra("alarm_data", alarmJson)
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    this,
                    alarmJson.hashCode(),
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, snoozeTime, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, snoozeTime, pendingIntent)
                }
                
                println("DEBUG: Alarm snoozed for $snoozeMinutes minutes")
            }
        } catch (e: Exception) {
            println("DEBUG: Error snoozing alarm: $e")
        }
    }

    private fun cancelAlarm() {
        try {
            val alarmJson = intent.getStringExtra("alarm_data")
            if (alarmJson != null) {
                val intent = Intent(this, AlarmReceiver::class.java).apply {
                    putExtra("alarm_data", alarmJson)
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    this,
                    alarmJson.hashCode(),
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                
                println("DEBUG: Alarm cancelled")
            }
        } catch (e: Exception) {
            println("DEBUG: Error cancelling alarm: $e")
        }
    }
}