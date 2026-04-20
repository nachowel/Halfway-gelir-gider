import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Transaction-style list row from hi-fi `.list-row`:
///   avatar icon tile (leading) · body (title + meta) · right-aligned trailing
///   bottom border `--border-soft` except last
///   padding 12px vertical, 4px horizontal
class HiFiListRow extends StatelessWidget {
  const HiFiListRow({
    required this.leading,
    required this.title,
    this.meta,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.ttl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    style: AppTypography.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );

    final Widget decorated = DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
            : null,
      ),
      child: body,
    );

    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: decorated),
    );
  }
}
