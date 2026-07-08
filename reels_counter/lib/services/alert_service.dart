import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles haptic feedback (every 10 reels) and the
/// "Take a break" notification when the daily limit is reached.
class AlertService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> vibrateIfMilestone(int count) async {
    if (count > 0 && count % 10 == 0) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 200);
      }
    }
  }

  Future<void> showBreakAlert() async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'reels_limit_channel',
      'Daily Limit Alerts',
      channelDescription: 'Notifies when your reel scroll limit is reached',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      0,
      '🧠 Take a break',
      "You've hit your reel scroll limit for today.",
      details,
    );
  }
}
