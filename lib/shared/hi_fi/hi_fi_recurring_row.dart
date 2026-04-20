import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'hi_fi_card.dart';
import 'hi_fi_icon_tile.dart';
import 'hi_fi_pill.dart';

/// Recurring item status (handoff §3 Recurring).
///   late  = expense_soft background + expense pill
///   soon  = amber_soft background + amber pill ("In N days")
///   later = neutral surface card (compact row with icon + chevron)
enum HiFiRecurringStatus { late, soon, later }

/// "Next-up" row from hi-fi Recurring variant A.
/// For [late] and [soon] the row is a padded warm card with a status pill,
/// serif title, frequency meta, right-aligned amount + pay CTA.
/// For [later] it collapses to a compact HiFiCard row (icon tile · body · amount).
class HiFiRecurringRow extends StatelessWidget {
  const HiFiRecurringRow({
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.frequencyMeta,
    required this.amount,
    required this.onPaidTap,
    this.icon,
    super.key,
  });

  final String title;
  final HiFiRecurringStatus status;

  /// e.g. "Late · 3d" / "In 2 days"
  final String statusLabel;

  /// e.g. "Every month · was due 13 Apr"
  final String frequencyMeta;
  final String amount;
  final VoidCallback onPaidTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (status == HiFiRecurringStatus.later) {
      return _LaterRow(
        title: title,
        meta: frequencyMeta,
        amount: amount,
        icon: icon ?? Icons.schedule_rounded,
      );
    }
    return _ImmediateCard(
      title: title,
      status: status,
      statusLabel: statusLabel,
      frequencyMeta: frequencyMeta,
      amount: amount,
      onPaidTap: onPaidTap,
    );
  }
}

class _ImmediateCard extends StatelessWidget {
  const _ImmediateCard({
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.frequencyMeta,
    required this.amount,
    required this.onPaidTap,
  });

  final String title;
  final HiFiRecurringStatus status;
  final String statusLabel;
  final String frequencyMeta;
  final String amount;
  final VoidCallback onPaidTap;

  ({
    Gradient gradient,
    Color border,
    HiFiPillTone pill,
    bool ghostCta,
    Color payBg,
    Color payFg,
    Color payBorder,
  })
  _tone() {
    switch (status) {
      case HiFiRecurringStatus.late:
        return (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF7E5DB), AppColors.expenseSoft],
          ),
          border: const Color(0xFFD89E89),
          pill: HiFiPillTone.expense,
          ghostCta: false,
          payBg: AppColors.ink,
          payFg: AppColors.onInk,
          payBorder: AppColors.ink,
        );
      case HiFiRecurringStatus.soon:
        return (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFFF0C7), AppColors.amberSoft],
          ),
          border: const Color(0xFFE1BE66),
          pill: HiFiPillTone.amber,
          ghostCta: true,
          payBg: const Color(0x26E8A93A),
          payFg: AppColors.amberInk,
          payBorder: const Color(0x88E1BE66),
        );
      case HiFiRecurringStatus.later:
        return (
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.surface, Color(0xFFF8F1E4)],
          ),
          border: AppColors.border,
          pill: HiFiPillTone.neutral,
          ghostCta: true,
          payBg: Colors.transparent,
          payFg: AppColors.inkSoft,
          payBorder: AppColors.border,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tone();
    return Container(
      decoration: BoxDecoration(
        gradient: t.gradient,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HiFiPill(label: statusLabel, tone: t.pill),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppTypography.h2.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  frequencyMeta,
                  style: AppTypography.bodySoft.copyWith(fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amount,
                style: AppTypography.numLg.copyWith(color: AppColors.expense),
              ),
              const SizedBox(height: 6),
              _PayPill(
                ghost: t.ghostCta,
                bg: t.payBg,
                fg: t.payFg,
                border: t.payBorder,
                onTap: onPaidTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayPill extends StatelessWidget {
  const _PayPill({
    required this.ghost,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });
  final bool ghost;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(999),
            boxShadow: ghost
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1409282B),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!ghost) ...<Widget>[
                Icon(Icons.check_rounded, size: 12, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                'Pay',
                style: AppTypography.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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

class _LaterRow extends StatelessWidget {
  const _LaterRow({
    required this.title,
    required this.meta,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String meta;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          HiFiIconTile(icon: icon, tone: HiFiIconTileTone.brand),
          const SizedBox(width: AppSpacing.smTight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.ttl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTypography.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.numMd.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}
