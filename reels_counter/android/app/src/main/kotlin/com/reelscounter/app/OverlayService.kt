package com.reelscounter.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * Draws an always-on-top pill ("🧠👁️ <count>") at the top-center of the
 * screen. Runs as a foreground service so Android doesn't kill it while
 * the overlay is visible.
 */
class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var pillView: TextView? = null
    private val countListener: (Int) -> Unit = { count ->
        pillView?.post { pillView?.text = "🧠👁️ $count" }
    }

    companion object {
        const val CHANNEL_ID = "overlay_service_channel"
        const val NOTIFICATION_ID = 1001
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundWithNotification()
        showOverlay()
        CounterBus.addListener(countListener)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun startForegroundWithNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Overlay Counter",
                NotificationManager.IMPORTANCE_MIN
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Reels Counter active")
            .setContentText("Tracking your reel scrolls")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun showOverlay() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 48 // top offset in px, adjusted for status bar

        val background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 60f
            setColor(Color.argb(170, 10, 10, 14))
            setStroke(2, Color.argb(60, 187, 134, 252)) // soft purple glow border
        }

        pillView = TextView(this).apply {
            text = "🧠👁️ ${CounterBus.currentCount}"
            setTextColor(Color.WHITE)
            textSize = 16f
            setPadding(36, 18, 36, 18)
            background = background
        }

        windowManager?.addView(pillView, params)
    }

    override fun onDestroy() {
        super.onDestroy()
        CounterBus.removeListener(countListener)
        pillView?.let {
            try {
                windowManager?.removeView(it)
            } catch (_: Exception) {
                // View may already be detached.
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
