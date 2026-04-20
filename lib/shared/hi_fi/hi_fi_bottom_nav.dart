import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

class HiFiNavItem {
  const HiFiNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Floating bottom nav from hi-fi `.bottomnav`:
///   background: rgba(251,247,237,0.95)
///   backdrop-filter: blur(8px)
///   border: 1px var(--border)
///   radius: 22
///   padding: 10 8 8
///   shadow: shadow-md
///   active item: brand color, bolder label (NOT a filled pill — hi-fi dashboard
///     variant A shows the active item using color only; the handoff mentions an
///     ink-filled pill as an alternative. We honor the hi-fi dashboard rendering.)
class HiFiBottomNav extends StatelessWidget {
  const HiFiBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<HiFiNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.bottomNav),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.bottomNav),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavSlot(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final HiFiNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.brand : AppColors.inkFade;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(item.icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTypography.meta.copyWith(
                fontSize: 10,
                letterSpacing: 0.2,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
