package com.oaptech.clock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.os.PowerManager
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.Calendar
import org.json.JSONObject
import java.text.SimpleDateFormat

class DummyAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Do nothing - this is just a dummy receiver for hiding alarm icon
        println("DEBUG: DummyAlarmReceiver triggered - this should not happen")
    }
}

fun stableAlarmRequestCode(id: String): Int {
    val parsed = id.toLongOrNull()
    if (parsed != null) return (parsed and 0x7FFFFFFF).toInt()

    var hash = 5381L
    for (character in id) {
        hash = hash * 33 + character.code
    }
    return kotlin.math.abs(hash).toInt() and 0x7FFFFFFF
}

class AlarmPlugin(private val context: Context) : MethodCallHandler {
    private var alarmManager: AlarmManager? = null
    private var currentRingtone: Ringtone? = null
    private var currentAlarmIconPendingIntent: PendingIntent? = null

    init {
        alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSystemRingtones" -> {
                Thread {
                    try {
                        val manager = RingtoneManager(context)
                        manager.setType(RingtoneManager.TYPE_RINGTONE or RingtoneManager.TYPE_ALARM)
                        val cursor = manager.cursor
                        val list = mutableListOf<Map<String, String>>()
                        if (cursor != null) {
                            while (cursor.moveToNext()) {
                                val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                                val uriStr = cursor.getString(RingtoneManager.URI_COLUMN_INDEX) + "/" + cursor.getString(RingtoneManager.ID_COLUMN_INDEX)
                                list.add(mapOf("title" to title, "uri" to uriStr))
                            }
                        }
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(list)
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.error("ERROR", e.message, null)
                        }
                    }
                }.start()
            }
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
                val alarmId = call.argument<String>("alarmId") ?: ""
                if (alarmJson != null && alarmTime > 0 && alarmId.isNotEmpty()) {
                    scheduleAlarm(alarmJson, alarmTime, alarmId)
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
            "startTimerRingActivity" -> {
                val remainingSeconds = call.argument<Int>("remaining_seconds") ?: 0
                val selectedSound = call.argument<String>("selected_sound") ?: "Radar"
                val selectedVibrate = call.argument<Boolean>("selected_vibrate") ?: false
                println("DEBUG: AlarmPlugin startTimerRingActivity called with remainingSeconds=$remainingSeconds, selectedSound=$selectedSound, selectedVibrate=$selectedVibrate")
                startTimerRingActivity(remainingSeconds, selectedSound, selectedVibrate)
                result.success(null)
            }
            "scheduleTimer" -> {
                val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                val selectedSound = call.argument<String>("selected_sound") ?: "Radar"
                val selectedVibrate = call.argument<Boolean>("selected_vibrate") ?: false
                if (triggerAtMillis > 0) {
                    scheduleTimer(triggerAtMillis, selectedSound, selectedVibrate)
                }
                result.success(null)
            }
            "cancelTimer" -> {
                cancelTimer()
                result.success(null)
            }
            "playSystemRingtone" -> {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    playSystemRingtone(uriString)
                }
                result.success(null)
            }
            "stopSystemRingtone" -> {
                stopSystemRingtone()
                result.success(null)
            }
            "playSystemRingtonePreview" -> {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    playSystemRingtonePreview(uriString)
                }
                result.success(null)
            }
            "stopSystemRingtonePreview" -> {
                stopSystemRingtonePreview()
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
            currentAlarmIconPendingIntent?.let { alarmManager?.cancel(it) }
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
            currentAlarmIconPendingIntent = pendingIntent
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun hideAlarmIcon() {
        currentAlarmIconPendingIntent?.let {
            alarmManager?.cancel(it)
            it.cancel()
        }
        currentAlarmIconPendingIntent = null
    }

    private fun scheduleAlarm(alarmJson: String, alarmTime: Long, alarmId: String) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarm_data", alarmJson)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            stableAlarmRequestCode(alarmId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = this.alarmManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Use setAlarmClock for better reliability on some devices
            val alarmInfo = AlarmManager.AlarmClockInfo(alarmTime, pendingIntent)
            alarmManager.setAlarmClock(alarmInfo, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, alarmTime, pendingIntent)
        }
        println("DEBUG: Alarm scheduled for ${java.util.Date(alarmTime)}")
    }

    private fun cancelAlarm(alarmId: String) {
        val intent = Intent(context, AlarmReceiver::class.java)
        cancelExistingAlarm(stableAlarmRequestCode(alarmId), intent)
        cancelExistingAlarm(alarmId.hashCode(), intent)
        println("DEBUG: Alarm cancelled for ID: $alarmId")
    }

    private fun cancelExistingAlarm(requestCode: Int, intent: Intent) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        ) ?: return
        alarmManager?.cancel(pendingIntent)
        pendingIntent.cancel()
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

    private fun startTimerRingActivity(remainingSeconds: Int, selectedSound: String, selectedVibrate: Boolean) {
        val intent = Intent(context, TimerRingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                   Intent.FLAG_ACTIVITY_SINGLE_TOP or
                   Intent.FLAG_ACTIVITY_CLEAR_TASK or
                   Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra("remaining_seconds", remainingSeconds)
            putExtra("selected_sound", selectedSound)
            putExtra("selected_vibrate", selectedVibrate)
            addFlags(Intent.FLAG_FROM_BACKGROUND)
        }
        println("DEBUG: AlarmPlugin starting TimerRingActivity")
        context.startActivity(intent)
        println("DEBUG: AlarmPlugin startActivity completed")
    }

    private fun scheduleTimer(triggerAtMillis: Long, selectedSound: String, selectedVibrate: Boolean) {
        val intent = Intent(context, TimerReceiver::class.java).apply {
            putExtra("selected_sound", selectedSound)
            putExtra("selected_vibrate", selectedVibrate)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            88888,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = this.alarmManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val alarmInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
            alarmManager.setAlarmClock(alarmInfo, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
        println("DEBUG: Timer scheduled for ${java.util.Date(triggerAtMillis)}")
    }

    private fun cancelTimer() {
        val intent = Intent(context, TimerReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            88888,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager?.cancel(pendingIntent)
        println("DEBUG: Timer cancelled")
    }

    private fun stopSystemRingtone() {
        try {
            currentRingtone?.stop()
            currentRingtone = null
            println("DEBUG: Stopped system ringtone")
        } catch (e: Exception) {
            println("DEBUG: Error stopping system ringtone: ${e.message}")
        }
    }

    private fun playSystemRingtone(uriString: String) {
        try {
            // Stop any currently playing ringtone
            stopSystemRingtone()

            val uri = Uri.parse(uriString)
            currentRingtone = RingtoneManager.getRingtone(context, uri)
            if (currentRingtone != null) {
                currentRingtone?.setStreamType(AudioManager.STREAM_ALARM)
                currentRingtone?.setLooping(true)
                currentRingtone?.play()
                println("DEBUG: Playing system ringtone: $uriString")
            } else {
                println("DEBUG: Could not get ringtone for URI: $uriString")
            }
        } catch (e: Exception) {
            println("DEBUG: Error playing system ringtone: ${e.message}")
        }
    }

    private fun playSystemRingtonePreview(uriString: String) {
        try {
            // Stop any currently playing preview ringtone
            stopSystemRingtonePreview()

            val uri = Uri.parse(uriString)
            currentRingtone = RingtoneManager.getRingtone(context, uri)
            if (currentRingtone != null) {
                currentRingtone?.setStreamType(AudioManager.STREAM_ALARM) // Use alarm stream for preview like the main alarm
                currentRingtone?.setLooping(false) // Don't loop for preview
                currentRingtone?.play()
                println("DEBUG: Playing system ringtone preview: $uriString")
            } else {
                println("DEBUG: Could not get ringtone for preview URI: $uriString")
            }
        } catch (e: Exception) {
            println("DEBUG: Error playing system ringtone preview: ${e.message}")
        }
    }

    private fun stopSystemRingtonePreview() {
        try {
            currentRingtone?.stop()
            currentRingtone = null
            println("DEBUG: Stopped system ringtone preview")
        } catch (e: Exception) {
            println("DEBUG: Error stopping system ringtone preview: ${e.message}")
        }
    }
}

// BroadcastReceiver to handle alarm triggers
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmJson = intent.getStringExtra("alarm_data")
        if (alarmJson != null) {
            println("DEBUG: AlarmReceiver triggered with alarm data: $alarmJson")

            if (!isCurrentEnabledAlarm(context, alarmJson)) {
                println("DEBUG: Ignoring stale, deleted, or disabled alarm payload")
                return
            }

            // Acquire wake lock to ensure screen turns on
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                "AlarmApp:AlarmWakeLock"
            )
            wakeLock.acquire(10 * 60 * 1000L) // 10 minutes timeout

            // Start AlarmRingActivity directly
            val activityIntent = Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP or
                       Intent.FLAG_ACTIVITY_CLEAR_TASK or
                       Intent.FLAG_ACTIVITY_NO_HISTORY
                putExtra("alarm_data", alarmJson)
                addFlags(Intent.FLAG_FROM_BACKGROUND)
                // Add overlay flags if needed
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            println("DEBUG: AlarmReceiver starting AlarmRingActivity directly")
            context.startActivity(activityIntent)
            println("DEBUG: AlarmReceiver startActivity completed")

            // Reschedule if repeating alarm
            try {
                val alarmObj = JSONObject(alarmJson)
                val repeatDays = alarmObj.optJSONArray("repeatDays")
                if (repeatDays != null && repeatDays.length() > 0) {
                    val timeStr = alarmObj.getString("time")
                val dateTime = java.util.Date(java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").parse(timeStr).time)
                val calendarTime = Calendar.getInstance()
                calendarTime.time = dateTime
                val hour = calendarTime.get(Calendar.HOUR_OF_DAY)
                val minute = calendarTime.get(Calendar.MINUTE)
                    var calendar = Calendar.getInstance()
                    calendar.set(Calendar.HOUR_OF_DAY, hour)
                    calendar.set(Calendar.MINUTE, minute)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    
                    // If time has passed today, add one day
                    if (calendar.timeInMillis <= System.currentTimeMillis()) {
                        calendar.add(Calendar.DAY_OF_MONTH, 1)
                    }
                    
                    // Find next valid day
                    var daysAdded = 0
                    val maxDays = 7
                    while (daysAdded < maxDays) {
                        val checkCalendar = calendar.clone() as Calendar
                        checkCalendar.add(Calendar.DAY_OF_MONTH, daysAdded)
                        val weekday = checkCalendar.get(Calendar.DAY_OF_WEEK)
                        // Convert to Monday=1, Sunday=7
                        val adjustedWeekday = if (weekday == Calendar.SUNDAY) 7 else weekday - 1
                        
                        var isValidDay = false
                        for (i in 0 until repeatDays.length()) {
                            if (repeatDays.getInt(i) == adjustedWeekday) {
                                isValidDay = true
                                break
                            }
                        }
                        
                        if (isValidDay) {
                            calendar = checkCalendar
                            break
                        }
                        daysAdded++
                    }
                    
                    // Schedule next alarm
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val nextIntent = Intent(context, AlarmReceiver::class.java).apply {
                        putExtra("alarm_data", alarmJson)
                    }
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        stableAlarmRequestCode(JSONObject(alarmJson).getString("id")),
                        nextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val alarmInfo = AlarmManager.AlarmClockInfo(calendar.timeInMillis, pendingIntent)
                        alarmManager.setAlarmClock(alarmInfo, pendingIntent)
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                    }
                    println("DEBUG: Rescheduled repeating alarm for ${java.util.Date(calendar.timeInMillis)}")
                }
            } catch (e: Exception) {
                println("DEBUG: Error rescheduling alarm: ${e.message}")
            }

            // Release wake lock after a short delay to let activity start
            wakeLock.release()
        } else {
            println("DEBUG: AlarmReceiver triggered but no alarm data found")
        }
    }

    private fun isCurrentEnabledAlarm(context: Context, alarmJson: String): Boolean {
        return try {
            val incoming = JSONObject(alarmJson)
            val alarmId = incoming.getString("id")
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val storedJson = prefs.getString("flutter.alarms", null) ?: return false
            val alarms = org.json.JSONArray(storedJson)
            for (index in 0 until alarms.length()) {
                val stored = alarms.getJSONObject(index)
                if (stored.optString("id") == alarmId) {
                    if (!stored.optBoolean("isEnabled", false)) return false
                    if (stored.optString("time") != incoming.optString("time")) return false
                    val storedDays = stored.optJSONArray("repeatDays")?.toString() ?: "[]"
                    val incomingDays = incoming.optJSONArray("repeatDays")?.toString() ?: "[]"
                    return storedDays == incomingDays
                }
            }
            false
        } catch (error: Exception) {
            println("DEBUG: Could not validate alarm payload: ${error.message}")
            false
        }
    }

    private fun showFullScreenNotification(context: Context, alarmJson: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel if needed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "alarm_channel",
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for alarms"
                setShowBadge(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Intent to open AlarmRingActivity
        val activityIntent = Intent(context, AlarmRingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                   Intent.FLAG_ACTIVITY_SINGLE_TOP or
                   Intent.FLAG_ACTIVITY_CLEAR_TASK or
                   Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra("alarm_data", alarmJson)
            addFlags(Intent.FLAG_FROM_BACKGROUND)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            alarmJson.hashCode(),
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, "alarm_channel")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Alarm")
            .setContentText("Tap to dismiss")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        notificationManager.notify(alarmJson.hashCode(), notification)
        println("DEBUG: Full screen notification shown for alarm")
    }
}
