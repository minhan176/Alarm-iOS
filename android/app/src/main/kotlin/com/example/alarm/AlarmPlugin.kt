package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
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
}