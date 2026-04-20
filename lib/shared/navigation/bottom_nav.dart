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
      key: const Key('bottom-nav'),
      borderRadius: BorderRadius.circular(AppRadius.bottomNav),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.bottomNav),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            boxShadow: AppShadows.md,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (int index = 0; index < items.length; index++)
                  Expanded(
                    child: _BottomNavSlot(
                      index: index,
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
    required this.index,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final int index;
  final BottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.brand : AppColors.inkFade;
    return Semantics(
      key: Key('bottom-nav-item-$index'),
      button: true,
      selected: active,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        highlightColor: Colors.transparent,
        splashColor: AppColors.brand.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(item.icon, size: 20, color: fg),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.meta.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.2,
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
