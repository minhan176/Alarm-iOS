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

class AlarmPlugin(private val context: Context) : MethodCallHandler {
    private var alarmManager: AlarmManager? = null
    private var currentRingtone: Ringtone? = null

    init {
        alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
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
        println("DEBUG: hideAlarmIcon called - trying multiple methods")
        if (alarmManager != null) {
            // Method 1: Try to cancel all possible alarm clock pending intents
            println("DEBUG: Method 1 - canceling all possible pending intents")
            try {
                for (i in 0..50) { // Try more IDs including the ones we used for showAlarmIcon
                    val intent = Intent(context, MainActivity::class.java)
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        i,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    alarmManager?.cancel(pendingIntent)
                }
                println("DEBUG: Method 1 completed - cancelled all pending intents")
            } catch (e: Exception) {
                println("DEBUG: Method 1 failed: ${e.message}")
            }

            // Method 2: Set a dummy alarm clock and immediately cancel it
            try {
                println("DEBUG: Method 2 - dummy alarm clock with BroadcastReceiver")
                val dummyTime = System.currentTimeMillis() + 1000 // 1 second from now
                val dummyIntent = Intent(context, DummyAlarmReceiver::class.java).apply {
                    action = "com.oaptech.clock.DUMMY_ALARM"
                }
                val dummyPendingIntent = PendingIntent.getBroadcast(
                    context,
                    999998, // Different ID
                    dummyIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val dummyAlarmClockInfo = AlarmManager.AlarmClockInfo(dummyTime, dummyPendingIntent)
                alarmManager?.setAlarmClock(dummyAlarmClockInfo, dummyPendingIntent)

                // Small delay then cancel
                Thread.sleep(100)
                alarmManager?.cancel(dummyPendingIntent)
                println("DEBUG: Method 2 completed - dummy alarm set and cancelled")
            } catch (e: Exception) {
                println("DEBUG: Method 2 failed: ${e.message}")
            }

            // Method 3: Try to set alarm clock to current time and cancel
            try {
                println("DEBUG: Method 3 - current time alarm with BroadcastReceiver")
                val currentTime = System.currentTimeMillis()
                val currentIntent = Intent(context, DummyAlarmReceiver::class.java)
                val currentPendingIntent = PendingIntent.getBroadcast(
                    context,
                    999997, // Another different ID
                    currentIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val currentAlarmClockInfo = AlarmManager.AlarmClockInfo(currentTime, currentPendingIntent)
                alarmManager?.setAlarmClock(currentAlarmClockInfo, currentPendingIntent)
                alarmManager?.cancel(currentPendingIntent)
                println("DEBUG: Method 3 completed - current time alarm set and cancelled")
            } catch (e: Exception) {
                println("DEBUG: Method 3 failed: ${e.message}")
            }

            // Method 4: Try reflection to access private methods
            try {
                println("DEBUG: Method 4 - reflection approach")
                val alarmManagerClass = AlarmManager::class.java

                // Try to find and call private methods that might help
                val methods = alarmManagerClass.declaredMethods
                for (method in methods) {
                    if (method.name.contains("cancel") || method.name.contains("clear") || method.name.contains("remove")) {
                        try {
                            method.isAccessible = true
                            if (method.parameterCount == 0) {
                                method.invoke(alarmManager)
                                println("DEBUG: Called private method: ${method.name}")
                            } else if (method.parameterCount == 1 && method.parameterTypes[0] == PendingIntent::class.java) {
                                val dummyIntent = Intent(context, DummyAlarmReceiver::class.java)
                                val dummyPendingIntent = PendingIntent.getBroadcast(
                                    context,
                                    999996,
                                    dummyIntent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                                method.invoke(alarmManager, dummyPendingIntent)
                                println("DEBUG: Called private method with pending intent: ${method.name}")
                            }
                        } catch (e: Exception) {
                            // Ignore individual method failures
                        }
                    }
                }
                println("DEBUG: Method 4 completed - reflection methods attempted")
            } catch (e: Exception) {
                println("DEBUG: Method 4 failed: ${e.message}")
            }

            println("DEBUG: hideAlarmIcon - all methods attempted")
        } else {
            println("DEBUG: alarmManager is null")
        }
    }

    private fun scheduleAlarm(alarmJson: String, alarmTime: Long, alarmId: String) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarm_data", alarmJson)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(), // Use alarm ID hash as request code
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
                        alarmJson.hashCode(),
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