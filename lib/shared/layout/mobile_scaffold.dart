import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool usePreviewFrame = constraints.maxWidth > maxWidth + 72;
        final double shellHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final Widget shell = SizedBox(
          width: maxWidth,
          height: shellHeight,
          child: child,
        );

        if (!usePreviewFrame) {
          return Align(
            alignment: alignment,
            child: SizedBox(
              width: constraints.maxWidth,
              height: shellHeight,
              child: child,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: alignment,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1214),
                borderRadius: BorderRadius.circular(44),
                boxShadow: AppShadows.lg,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: shell,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
