import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter_data.dart';

/// Handles all local persistence for the counter, settings, and daily reset logic.
class StorageService {
  static const _kCount = 'reels_count';
  static const _kLimit = 'daily_limit';
  static const _kTracking = 'tracking_enabled';
  static const _kOverlay = 'overlay_enabled';
  static const _kLastReset = 'last_reset_date';

  Future<CounterData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_kLastReset);
    final lastReset = lastResetStr != null
        ? DateTime.parse(lastResetStr)
        : DateTime.now();

    int count = prefs.getInt(_kCount) ?? 0;

    // Auto-reset count if the day has changed.
    final now = DateTime.now();
    final isNewDay = now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;
    if (isNewDay) {
      count = 0;
      await prefs.setInt(_kCount, 0);
      await prefs.setString(_kLastReset, now.toIso8601String());
    }

    return CounterData(
      count: count,
      dailyLimit: prefs.getInt(_kLimit) ?? 20,
      trackingEnabled: prefs.getBool(_kTracking) ?? true,
      overlayEnabled: prefs.getBool(_kOverlay) ?? true,
      lastResetDate: isNewDay ? now : lastReset,
    );
  }

  Future<void> saveCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCount, count);
  }

  Future<void> saveLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLimit, limit);
  }

  Future<void> saveTrackingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTracking, value);
  }

  Future<void> saveOverlayEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOverlay, value);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCount, 0);
    await prefs.setString(_kLastReset, DateTime.now().toIso8601String());
  }
}
