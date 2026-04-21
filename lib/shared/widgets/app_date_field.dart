import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'app_form_section_card.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.showTodayPill = false,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showTodayPill;

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      label: label,
      trailing: showTodayPill ? const _TodayPill() : null,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontSize: 14.5),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        context.strings.today,
        style: AppTypography.meta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}
