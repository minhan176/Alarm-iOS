package com.oaptech.clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager

class TimerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        println("DEBUG: TimerReceiver triggered")

        val selectedSound = intent.getStringExtra("selected_sound") ?: "Radar"
        val selectedVibrate = intent.getBooleanExtra("selected_vibrate", false)

        // Acquire wake lock to ensure screen turns on
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "AlarmApp:TimerWakeLock"
        )
        wakeLock.acquire(10 * 60 * 1000L) // 10 minutes timeout

        // Start TimerRingActivity
        val activityIntent = Intent(context, TimerRingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                   Intent.FLAG_ACTIVITY_SINGLE_TOP or
                   Intent.FLAG_ACTIVITY_CLEAR_TASK or
                   Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra("remaining_seconds", 0)
            putExtra("selected_sound", selectedSound)
            putExtra("selected_vibrate", selectedVibrate)
            addFlags(Intent.FLAG_FROM_BACKGROUND)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        println("DEBUG: TimerReceiver starting TimerRingActivity")
        context.startActivity(activityIntent)
        println("DEBUG: TimerReceiver startActivity completed")

        wakeLock.release()
    }
}
