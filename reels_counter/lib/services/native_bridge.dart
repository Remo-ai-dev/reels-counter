import 'dart:async';
import 'package:flutter/services.dart';

/// Bridges Dart <-> native Android code for:
/// - Starting/stopping the Accessibility Service that detects reel swipes
/// - Starting/stopping the floating overlay window
/// - Requesting the special permissions both require
/// - Receiving live count updates broadcast from the native AccessibilityService
class NativeBridge {
  static const MethodChannel _channel = MethodChannel('reels_counter/control');
  static const EventChannel _eventChannel = EventChannel('reels_counter/events');

  Stream<int>? _countStream;

  /// Emits the latest count every time the native side detects a new swipe.
  Stream<int> get onCountChanged {
    _countStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as int);
    return _countStream!;
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled');
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod('hasOverlayPermission');
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  Future<void> startOverlay() async {
    await _channel.invokeMethod('startOverlay');
  }

  Future<void> stopOverlay() async {
    await _channel.invokeMethod('stopOverlay');
  }

  Future<void> updateOverlayCount(int count) async {
    await _channel.invokeMethod('updateOverlayCount', {'count': count});
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    await _channel.invokeMethod('setTrackingEnabled', {'enabled': enabled});
  }

  Future<void> syncCount(int count) async {
    // Tell the native service what the current count is (e.g. after a reset)
    await _channel.invokeMethod('syncCount', {'count': count});
  }
}
