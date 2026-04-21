import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../shared/hi_fi/hi_fi_fab.dart';
import '../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../shared/layout/mobile_scaffold.dart';
import '../../shared/overlay/app_overlay.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_localizations.dart';
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

  String _locationForIndex(int index) {
    switch (index) {
      case 0:
        return '/summary';
      case 1:
        return '/transactions';
      case 2:
        return '/reports';
      case 3:
        return '/settings';
    }
    return '/summary';
  }

  void _onNavTap(BuildContext context, int index) {
    final String targetLocation = _locationForIndex(index);
    if (currentLocation == targetLocation) {
      return;
    }
    context.go(targetLocation);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final List<BottomNavItem> navItems = <BottomNavItem>[
      BottomNavItem(icon: Icons.home_rounded, label: strings.dashboardSummary),
      BottomNavItem(icon: Icons.list_alt_rounded, label: strings.transactions),
      BottomNavItem(
        icon: Icons.insert_chart_outlined_rounded,
        label: strings.reports,
      ),
      BottomNavItem(icon: Icons.settings_outlined, label: strings.settings),
    ];
    final MediaQueryData mq = MediaQuery.of(context);
    final double bottomInset = mq.viewInsets.bottom;
    final double bottomDockInset = bottomInset > 0
        ? bottomInset + 12
        : mq.padding.bottom + 16;
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _ShellFabSlot(
        bottomDockInset: bottomDockInset,
        onPressed: () => _showQuickActions(context),
      ),
      body: MobileScaffold(
        child: HiFiScreenBackground(
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: child),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: bottomDockInset,
                  child: BottomNav(
                    items: navItems,
                    currentIndex: _currentIndex,
                    onTap: (int i) => _onNavTap(context, i),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickActions(BuildContext context) async {
    final _QuickAction? action = await showAppModalBottomSheet<_QuickAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _QuickActionsSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onIncomeTap: () =>
              Navigator.of(sheetContext).pop(_QuickAction.income),
          onExpenseTap: () =>
              Navigator.of(sheetContext).pop(_QuickAction.expense),
          onRecurringTap: () =>
              Navigator.of(sheetContext).pop(_QuickAction.recurring),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _QuickAction.income:
        context.push('/entry/income');
        return;
      case _QuickAction.expense:
        context.push('/entry/expense');
        return;
      case _QuickAction.recurring:
        context.push('/settings/recurring');
        return;
    }
  }
}

enum _QuickAction { income, expense, recurring }

class _ShellFabSlot extends ConsumerWidget {
  const _ShellFabSlot({required this.bottomDockInset, required this.onPressed});

  final double bottomDockInset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOverlayOpen = ref.watch(isOverlayOpenProvider);

    return Padding(
      padding: EdgeInsets.only(right: 4, bottom: bottomDockInset + 60),
      child: IgnorePointer(
        ignoring: isOverlayOpen,
        child: SizedBox(
          width: 56,
          height: 56,
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            reverseDuration: AppDurations.fast,
            switchInCurve: AppEasing.expressive,
            switchOutCurve: AppEasing.standard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<double> fade = CurvedAnimation(
                parent: animation,
                curve: AppEasing.standard,
              );
              final Animation<double> scale = Tween<double>(begin: 0.92, end: 1)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppEasing.expressive,
                    ),
                  );
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: isOverlayOpen
                ? const SizedBox.square(
                    key: ValueKey<String>('shell-fab-hidden'),
                    dimension: 56,
                  )
                : HiFiFab(
                    key: const ValueKey<String>('shell-fab-visible'),
                    onPressed: onPressed,
                  ),
          ),
        ),
      ),
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
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.addNew.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: AppTypography.h2,
              children: <InlineSpan>[
                TextSpan(
                  text: strings.locale == AppLocale.en
                      ? 'What did you just '
                      : 'Az once ne ',
                ),
                TextSpan(
                  text: strings.locale == AppLocale.en ? 'do' : 'yaptiniz',
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
            title: strings.addIncome,
            meta: strings.addIncomeMeta,
            onTap: onIncomeTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SheetAction(
            icon: Icons.trending_down_rounded,
            tone: HiFiIconTileTone.expense,
            title: strings.addExpense,
            meta: strings.addExpenseMeta,
            onTap: onExpenseTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SheetAction(
            icon: Icons.event_repeat_rounded,
            tone: HiFiIconTileTone.amber,
            title: strings.addRecurringExpense,
            meta: strings.addRecurringMeta,
            onTap: onRecurringTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: strings.cancel,
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
