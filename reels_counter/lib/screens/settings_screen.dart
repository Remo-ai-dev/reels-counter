import 'package:flutter/material.dart';
import '../models/counter_data.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final CounterData data;
  final ValueChanged<int> onLimitChanged;

  const SettingsScreen({
    super.key,
    required this.data,
    required this.onLimitChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _limit;
  final _storage = StorageService();

  static const _limitOptions = [10, 20, 50];

  @override
  void initState() {
    super.initState();
    _limit = widget.data.dailyLimit;
  }

  Future<void> _confirmResetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This clears your counter and resets settings to default. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.resetAll();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Daily limit', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _limitOptions.map((option) {
              final selected = _limit == option;
              return ChoiceChip(
                label: Text('$option'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _limit = option);
                  widget.onLimitChanged(option);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'About vibration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your phone will vibrate once every 10 reels scrolled, and a "Take a break" alert appears when you hit your daily limit.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Privacy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'This app only counts scroll/swipe events using Android\'s Accessibility API. '
            'It never records your screen, never saves video content, and never sends data off your device.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmResetData,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('Reset all data', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
