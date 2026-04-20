import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Circular FAB from hi-fi `.fab`:
///   56x56 circle
///   linear-gradient(145deg, #0E6B6F, #094A4D)
///   cream icon
///   shadow: 0 8px 20px rgba(9,74,77,0.35), 0 2px 4px rgba(9,74,77,0.2)
class HiFiFab extends StatefulWidget {
  const HiFiFab({
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.size = 56,
    this.heroTag,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Object? heroTag;

  @override
  State<HiFiFab> createState() => _HiFiFabState();
}

class _HiFiFabState extends State<HiFiFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 1.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 140),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(_) {
    _controller.animateTo(
      0.92,
      duration: const Duration(milliseconds: 80),
      curve: AppEasing.standard,
    );
  }

  void _tapUp(_) {
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 140),
      curve: AppEasing.expressive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget core = Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.fab,
        boxShadow: AppShadows.fab,
      ),
      child: Icon(widget.icon, size: widget.size * 0.4, color: AppColors.onInk),
    );

    final Widget pressable = GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: () => _tapUp(null),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _controller, child: core),
    );

    if (widget.heroTag == null) {
      return pressable;
    }
    return Hero(tag: widget.heroTag!, child: pressable);
  }
}
