package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class AlarmPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var alarmManager: AlarmManager? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.alarm/alarm")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showAlarmIcon" -> {
                val alarmId = call.argument<Int>("alarmId") ?: 0
                val timestamp = call.argument<Long>("timestamp") ?: 0L
                val label = call.argument<String>("label") ?: "Alarm"

                showAlarmIcon(alarmId, timestamp, label)
                result.success(null)
            }
            "hideAlarmIcon" -> {
                hideAlarmIcon()
                result.success(null)
            }
            "scheduleAlarm" -> {
                val alarmJson = call.argument<String>("alarm")
                val alarmTime = call.argument<Long>("alarmTime") ?: 0L
                if (alarmJson != null && alarmTime > 0) {
                    scheduleAlarm(alarmJson, alarmTime)
                }
                result.success(null)
            }
            "cancelAlarm" -> {
                val alarmId = call.argument<String>("alarmId") ?: ""
                cancelAlarm(alarmId)
                result.success(null)
            }
            "openRingScreen" -> {
                val alarmJson = call.argument<String>("alarm")
                if (alarmJson != null) {
                    println("DEBUG: AlarmPlugin openRingScreen called with alarm: $alarmJson")
                    openRingScreen(alarmJson)
                } else {
                    println("DEBUG: AlarmPlugin openRingScreen called but alarm is null")
                }
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun showAlarmIcon(alarmId: Int, timestamp: Long, label: String) {
        if (alarmManager != null) {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("alarm_id", alarmId)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val alarmClockInfo = AlarmManager.AlarmClockInfo(timestamp, pendingIntent)
            alarmManager?.setAlarmClock(alarmClockInfo, pendingIntent)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun hideAlarmIcon() {
        if (alarmManager != null) {
            // Cancel all alarm clock intents
            for (i in 0..999) { // Assuming alarm IDs are within this range
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    i,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager?.cancel(pendingIntent)
            }
        }
    }

    private fun scheduleAlarm(alarmJson: String, alarmTime: Long) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarm_data", alarmJson)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmJson.hashCode(), // Use alarm JSON hash as request code
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (alarmManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarmTime, pendingIntent)
            } else {
                alarmManager?.setExact(AlarmManager.RTC_WAKEUP, alarmTime, pendingIntent)
            }
            println("DEBUG: Alarm scheduled for ${java.util.Date(alarmTime)}")
        }
    }

    private fun cancelAlarm(alarmId: String) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager?.cancel(pendingIntent)
        println("DEBUG: Alarm cancelled for ID: $alarmId")
    }

    private fun openRingScreen(alarmJson: String) {
        println("DEBUG: openRingScreen starting MainActivity with alarm data")
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("open_ring_screen", true)
            putExtra("alarm_data", alarmJson)
        }
        context.startActivity(intent)
        println("DEBUG: openRingScreen startActivity called")
    }
}

// BroadcastReceiver to handle alarm triggers
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmJson = intent.getStringExtra("alarm_data")
        if (alarmJson != null) {
            println("DEBUG: AlarmReceiver triggered with alarm data: $alarmJson")
            // Start AlarmRingActivity with alarm data
            val activityIntent = Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("alarm_data", alarmJson)
            }
            println("DEBUG: AlarmReceiver starting AlarmRingActivity")
            context.startActivity(activityIntent)
            println("DEBUG: AlarmReceiver startActivity completed")
        } else {
            println("DEBUG: AlarmReceiver triggered but no alarm data found")
        }
    }
}