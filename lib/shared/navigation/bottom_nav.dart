import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

class BottomNavItem {
  const BottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class BottomNav extends StatelessWidget {
  const BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.bottomNav),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.bottomNav),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            boxShadow: AppShadows.md,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: <Widget>[
                for (int index = 0; index < items.length; index++)
                  Expanded(
                    child: _BottomNavSlot(
                      item: items[index],
                      active: index == currentIndex,
                      onTap: () => onTap(index),
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

class _BottomNavSlot extends StatelessWidget {
  const _BottomNavSlot({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.onInk : AppColors.inkFade;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppEasing.standard,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(item.icon, size: 20, color: fg),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.meta.copyWith(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
