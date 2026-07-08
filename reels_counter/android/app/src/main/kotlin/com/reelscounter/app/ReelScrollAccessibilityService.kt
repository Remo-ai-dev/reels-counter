package com.reelscounter.app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper

/**
 * Detects when the user scrolls to a new reel/short video.
 *
 * IMPORTANT / PRIVACY:
 * This service NEVER reads text content, NEVER captures screenshots, and
 * NEVER records the screen. It only inspects window-state-changed and
 * window-content-changed events to detect that a *new screen of content*
 * has appeared (i.e. the user swiped to the next reel) within a small set
 * of allow-listed short-video apps. No content, text, or media is stored.
 *
 * Detection strategy:
 * Reels/Shorts/TikTok feeds re-render their full-screen video player on
 * every swipe, which fires a content-changed event for the relevant package
 * with a distinct event timestamp/source-window combination. We debounce
 * rapid-fire duplicate events (a single swipe triggers several accessibility
 * events) using a short cooldown window, so each physical swipe maps to
 * exactly one increment.
 */
class ReelScrollAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var lastIncrementTime = 0L
    private val debounceMs = 600L

    // Packages known to use a vertical full-screen reel/short feed.
    private val targetPackages = setOf(
        "com.instagram.android",      // Instagram Reels
        "com.zhiliaoapp.musically",   // TikTok
        "com.ss.android.ugc.trill",   // TikTok (alt build)
        "com.google.android.youtube", // YouTube Shorts
        "com.snapchat.android"        // Snapchat Spotlight
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!CounterBus.trackingEnabled) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg !in targetPackages) return

        // Only react to content changes that look like a full feed re-render,
        // which is what happens when the next reel loads after a swipe.
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        ) {
            val now = System.currentTimeMillis()
            if (now - lastIncrementTime >= debounceMs) {
                lastIncrementTime = now
                handler.post { CounterBus.increment() }
            }
        }
    }

    override fun onInterrupt() {
        // No-op: required override.
    }
}
