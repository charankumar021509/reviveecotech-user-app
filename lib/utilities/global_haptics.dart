import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalHapticWrapper extends StatelessWidget {
  final Widget child;
  const GlobalHapticWrapper({super.key, required this.child});

  static DateTime _lastFeedback = DateTime.now();

  bool _shouldTrigger() {
    final now = DateTime.now();
    if (now.difference(_lastFeedback).inMilliseconds < 120) {
      return false;
    }
    _lastFeedback = now;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,

      // Fires ONLY when a tap gesture is recognized
      onTapDown: (_) {
        if (_shouldTrigger()) {
          HapticFeedback.selectionClick();
        }
      },

      child: child,
    );
  }
}
