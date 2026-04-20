import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../shared/hi_fi/hi_fi_fab.dart';
import '../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../shared/layout/mobile_scaffold.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _currentIndex {
    if (currentLocation.startsWith('/transactions')) return 1;
    if (currentLocation.startsWith('/reports')) return 2;
    if (currentLocation.startsWith('/settings')) return 3;
    return 0;
  }

  static const List<BottomNavItem> _navItems = <BottomNavItem>[
    BottomNavItem(icon: Icons.home_rounded, label: 'Ozet'),
    BottomNavItem(icon: Icons.list_alt_rounded, label: 'Islemler'),
    BottomNavItem(
      icon: Icons.insert_chart_outlined_rounded,
      label: 'Raporlar',
    ),
    BottomNavItem(icon: Icons.settings_outlined, label: 'Ayarlar'),
  ];

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/summary');
      case 1:
        context.go('/transactions');
      case 2:
        context.go('/reports');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double bottomInset = mq.viewInsets.bottom;
    final double bottomDockInset = bottomInset > 0
        ? bottomInset + 12
        : mq.padding.bottom + 16;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: HiFiScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: MobileScaffold(child: child)),
              Positioned(
                left: 14,
                right: 14,
                bottom: bottomDockInset,
                child: BottomNav(
                  items: _navItems,
                  currentIndex: _currentIndex,
                  onTap: (int i) => _onNavTap(context, i),
                ),
              ),
              Positioned(
                right: 20,
                bottom: bottomDockInset + 76,
                child: HiFiFab(onPressed: () => _showQuickActions(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _QuickActionsSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onIncomeTap: () {
            Navigator.of(sheetContext).pop();
            context.push('/entry/income');
          },
          onExpenseTap: () {
            Navigator.of(sheetContext).pop();
            context.push('/entry/expense');
          },
          onRecurringTap: () {
            Navigator.of(sheetContext).pop();
            context.push('/settings/recurring');
          },
        );
      },
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({
    required this.onClose,
    required this.onIncomeTap,
    required this.onExpenseTap,
    required this.onRecurringTap,
  });

  final VoidCallback onClose;
  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onRecurringTap;

  @override
  Widget build(BuildContext context) {
    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('ADD NEW', style: AppTypography.eye),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: AppTypography.h2,
              children: <InlineSpan>[
                const TextSpan(text: 'What did you just '),
                TextSpan(
                  text: 'do',
                  style: AppTypography.h2.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.brand,
                  ),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetAction(
            icon: Icons.trending_up_rounded,
            tone: HiFiIconTileTone.income,
            title: 'Gelir ekle',
            meta: 'Income · sale, payout, transfer',
            onTap: onIncomeTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SheetAction(
            icon: Icons.trending_down_rounded,
            tone: HiFiIconTileTone.expense,
            title: 'Gider ekle',
            meta: 'Expense · supplies, fuel, food',
            onTap: onExpenseTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SheetAction(
            icon: Icons.event_repeat_rounded,
            tone: HiFiIconTileTone.amber,
            title: 'Tekrarlayan gider',
            meta: 'Recurring · rent, bills, insurance',
            onTap: onRecurringTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            onPressed: onClose,
            variant: AppButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.tone,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final HiFiIconTileTone tone;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          HiFiIconTile(icon: icon, tone: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.ttl),
                const SizedBox(height: 2),
                Text(meta, style: AppTypography.meta),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFade),
        ],
      ),
    );
  }
}
