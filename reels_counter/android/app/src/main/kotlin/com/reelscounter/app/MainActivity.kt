package com.reelscounter.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val controlChannelName = "reels_counter/control"
    private val eventChannelName = "reels_counter/events"
    private var eventSink: EventChannel.EventSink? = null

    private val countListener: (Int) -> Unit = { count ->
        eventSink?.success(count)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "hasOverlayPermission" -> result.success(hasOverlayPermission())
                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(null)
                    }
                    "startOverlay" -> {
                        startService(Intent(this, OverlayService::class.java))
                        result.success(null)
                    }
                    "stopOverlay" -> {
                        stopService(Intent(this, OverlayService::class.java))
                        result.success(null)
                    }
                    "updateOverlayCount" -> {
                        val count = call.argument<Int>("count") ?: 0
                        CounterBus.setCount(count)
                        result.success(null)
                    }
                    "setTrackingEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        CounterBus.trackingEnabled = enabled
                        result.success(null)
                    }
                    "syncCount" -> {
                        val count = call.argument<Int>("count") ?: 0
                        CounterBus.setCount(count)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    CounterBus.addListener(countListener)
                }

                override fun onCancel(arguments: Any?) {
                    CounterBus.removeListener(countListener)
                    eventSink = null
                }
            })
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC
        )
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
                it.resolveInfo.serviceInfo.name == ReelScrollAccessibilityService::class.java.name
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !hasOverlayPermission()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }
}
