import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

enum HiFiAttachmentTone { neutral, income, expense }

class HiFiAttachmentTile extends StatelessWidget {
  const HiFiAttachmentTile({
    required this.label,
    required this.hint,
    required this.onTap,
    this.attachmentLabel,
    this.tone = HiFiAttachmentTone.neutral,
    super.key,
  });

  final String label;
  final String hint;
  final String? attachmentLabel;
  final VoidCallback onTap;
  final HiFiAttachmentTone tone;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg, Color border}) colors = switch (tone) {
      HiFiAttachmentTone.neutral => (
        bg: Colors.white.withValues(alpha: 0.26),
        fg: AppColors.inkFade,
        border: AppColors.border,
      ),
      HiFiAttachmentTone.income => (
        bg: AppColors.incomeSoft.withValues(alpha: 0.4),
        fg: AppColors.incomeInk,
        border: AppColors.income.withValues(alpha: 0.22),
      ),
      HiFiAttachmentTone.expense => (
        bg: AppColors.expenseSoft.withValues(alpha: 0.4),
        fg: AppColors.expenseInk,
        border: AppColors.expense.withValues(alpha: 0.22),
      ),
    };

    final bool attached = attachmentLabel != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          child: CustomPaint(
            painter: attached
                ? null
                : _DashedRoundedRectPainter(color: colors.border, radius: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
                border: attached ? Border.all(color: colors.border) : null,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    attached
                        ? Icons.attach_file_rounded
                        : Icons.camera_alt_outlined,
                    size: 18,
                    color: colors.fg,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(label, style: AppTypography.lbl),
                        const SizedBox(height: 2),
                        Text(
                          attachmentLabel ?? hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (attached
                                      ? AppTypography.body
                                      : AppTypography.meta)
                                  .copyWith(color: colors.fg),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    attached ? 'Clear' : 'Add',
                    style: AppTypography.meta.copyWith(color: colors.fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = math.min(distance + 6, metric.length);
        final Path segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
