package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class DummyAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Do nothing - this is just a dummy receiver for hiding alarm icon
        println("DEBUG: DummyAlarmReceiver triggered - this should not happen")
    }
}

class AlarmPlugin(private val context: Context) : MethodCallHandler {
    private var alarmManager: AlarmManager? = null

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
                    action = "com.example.alarm.DUMMY_ALARM"
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

            // Start AlarmRingActivity with alarm data
            val activityIntent = Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP or
                       Intent.FLAG_ACTIVITY_CLEAR_TASK or
                       Intent.FLAG_ACTIVITY_NO_HISTORY
                putExtra("alarm_data", alarmJson)
                // Add these to ensure it shows on lock screen
                addFlags(Intent.FLAG_FROM_BACKGROUND)
            }
            println("DEBUG: AlarmReceiver starting AlarmRingActivity")
            context.startActivity(activityIntent)
            println("DEBUG: AlarmReceiver startActivity completed")

            // Release wake lock after a short delay to let activity start
            wakeLock.release()
        } else {
            println("DEBUG: AlarmReceiver triggered but no alarm data found")
        }
    }
}