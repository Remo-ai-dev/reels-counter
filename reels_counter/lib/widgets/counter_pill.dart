import 'package:flutter/material.dart';

/// The dark, glowing pill that shows "🧠👁️ <count>".
/// Used in-app as a live preview of what the floating overlay looks like.
class CounterPill extends StatefulWidget {
  final int count;

  const CounterPill({super.key, required this.count});

  @override
  State<CounterPill> createState() => _CounterPillState();
}

class _CounterPillState extends State<CounterPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
  }

  @override
  void didUpdateWidget(CounterPill old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Text(
          '🧠👁️ ${widget.count}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
