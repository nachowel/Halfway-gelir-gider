import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'app_card.dart';

class AppFormSectionCard extends StatelessWidget {
  const AppFormSectionCard({
    required this.label,
    required this.child,
    this.trailing,
    this.helper,
    this.errorText,
    this.onTap,
    super.key,
  });

  final String label;
  final Widget child;
  final Widget? trailing;
  final String? helper;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppCard.compact(
          onTap: onTap,
          border: Border.all(
            color: hasError
                ? AppColors.expense.withValues(alpha: 0.28)
                : AppColors.border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(label, style: AppTypography.lbl)),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              child,
            ],
          ),
        ),
        if (helper != null || errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              errorText ?? helper!,
              style: AppTypography.meta.copyWith(
                color: hasError ? AppColors.expense : AppColors.inkFade,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
