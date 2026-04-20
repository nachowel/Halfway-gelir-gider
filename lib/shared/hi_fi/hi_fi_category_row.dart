import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'hi_fi_icon_tile.dart';

class HiFiCategoryRow extends StatelessWidget {
  const HiFiCategoryRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.meta,
    this.onTap,
    this.showDivider = true,
    this.showDragHandle = true,
    super.key,
  });

  final IconData icon;
  final HiFiIconTileTone tone;
  final String title;
  final String meta;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: <Widget>[
          if (showDragHandle) ...<Widget>[
            const Icon(
              Icons.drag_indicator_rounded,
              size: 16,
              color: AppColors.inkFade,
            ),
            const SizedBox(width: 8),
          ],
          HiFiIconTile(icon: icon, tone: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ttl,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.inkFade,
          ),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}
