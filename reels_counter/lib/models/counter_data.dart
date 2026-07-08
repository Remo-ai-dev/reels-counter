class CounterData {
  final int count;
  final int dailyLimit;
  final bool trackingEnabled;
  final bool overlayEnabled;
  final DateTime lastResetDate;

  CounterData({
    required this.count,
    required this.dailyLimit,
    required this.trackingEnabled,
    required this.overlayEnabled,
    required this.lastResetDate,
  });

  CounterData copyWith({
    int? count,
    int? dailyLimit,
    bool? trackingEnabled,
    bool? overlayEnabled,
    DateTime? lastResetDate,
  }) {
    return CounterData(
      count: count ?? this.count,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  factory CounterData.initial() {
    return CounterData(
      count: 0,
      dailyLimit: 20,
      trackingEnabled: true,
      overlayEnabled: true,
      lastResetDate: DateTime.now(),
    );
  }
}
