import 'package:flutter/material.dart';
import '../models/counter_data.dart';
import '../services/storage_service.dart';
import '../services/native_bridge.dart';
import '../services/alert_service.dart';
import '../widgets/counter_pill.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _bridge = NativeBridge();
  final _alerts = AlertService();

  CounterData _data = CounterData.initial();
  bool _accessibilityEnabled = false;
  bool _overlayPermissionGranted = false;
  bool _alertShownForLimit = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _bridge.onCountChanged.listen(_onNativeCountChanged);
  }

  Future<void> _bootstrap() async {
    final data = await _storage.load();
    final accessibility = await _bridge.isAccessibilityServiceEnabled();
    final overlayPerm = await _bridge.hasOverlayPermission();
    setState(() {
      _data = data;
      _accessibilityEnabled = accessibility;
      _overlayPermissionGranted = overlayPerm;
    });
    await _bridge.syncCount(data.count);
  }

  Future<void> _onNativeCountChanged(int count) async {
    setState(() => _data = _data.copyWith(count: count));
    await _storage.saveCount(count);
    await _bridge.updateOverlayCount(count);
    await _alerts.vibrateIfMilestone(count);

    if (count >= _data.dailyLimit && !_alertShownForLimit) {
      _alertShownForLimit = true;
      await _alerts.showBreakAlert();
    } else if (count < _data.dailyLimit) {
      _alertShownForLimit = false;
    }
  }

  Future<void> _resetCounter() async {
    await _storage.resetAll();
    await _bridge.syncCount(0);
    setState(() {
      _data = _data.copyWith(count: 0);
      _alertShownForLimit = false;
    });
  }

  Future<void> _toggleTracking(bool value) async {
    setState(() => _data = _data.copyWith(trackingEnabled: value));
    await _storage.saveTrackingEnabled(value);
    await _bridge.setTrackingEnabled(value);
  }

  Future<void> _toggleOverlay(bool value) async {
    if (value && !_overlayPermissionGranted) {
      await _bridge.requestOverlayPermission();
      final granted = await _bridge.hasOverlayPermission();
      setState(() => _overlayPermissionGranted = granted);
      if (!granted) return;
    }
    setState(() => _data = _data.copyWith(overlayEnabled: value));
    await _storage.saveOverlayEnabled(value);
    if (value) {
      await _bridge.startOverlay();
    } else {
      await _bridge.stopOverlay();
    }
  }

  Future<void> _enableAccessibility() async {
    await _bridge.openAccessibilitySettings();
    // Re-check after returning from settings (best-effort, user must back out manually).
    await Future.delayed(const Duration(seconds: 1));
    final enabled = await _bridge.isAccessibilityServiceEnabled();
    setState(() => _accessibilityEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_data.count / _data.dailyLimit).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    data: _data,
                    onLimitChanged: (limit) async {
                      await _storage.saveLimit(limit);
                      setState(() => _data = _data.copyWith(dailyLimit: limit));
                    },
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (!_accessibilityEnabled) _buildPermissionBanner(
                icon: Icons.accessibility_new,
                text: 'Enable the Accessibility Service so scrolls can be counted in Instagram, TikTok & YouTube.',
                actionLabel: 'Enable',
                onTap: _enableAccessibility,
              ),
              if (!_overlayPermissionGranted) _buildPermissionBanner(
                icon: Icons.layers,
                text: 'Grant the "display over other apps" permission to show the floating counter.',
                actionLabel: 'Grant',
                onTap: () async {
                  await _bridge.requestOverlayPermission();
                  final granted = await _bridge.hasOverlayPermission();
                  setState(() => _overlayPermissionGranted = granted);
                },
              ),
              const SizedBox(height: 32),
              CounterPill(count: _data.count),
              const SizedBox(height: 24),
              Text(
                '${_data.count} / ${_data.dailyLimit} reels today',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: progress >= 1.0 ? Colors.redAccent : Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 40),
              _buildToggleRow(
                'Tracking enabled',
                _data.trackingEnabled,
                _toggleTracking,
                Icons.track_changes,
              ),
              _buildToggleRow(
                'Floating overlay',
                _data.overlayEnabled,
                _toggleOverlay,
                Icons.picture_in_picture_alt,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetCounter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset counter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBanner({
    required IconData icon,
    required String text,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
