import 'package:flutter/material.dart';

/// Centers content in a mobile-first column on wider devices (tablet / web /
/// desktop previews). Target phone width per design brief is 360-430px.
class MobileScaffold extends StatelessWidget {
  const MobileScaffold({
    required this.child,
    this.maxWidth = 430,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
