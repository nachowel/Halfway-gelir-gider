import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

enum AppAmountFieldTone { expense, income }

class AppAmountField extends StatefulWidget {
  const AppAmountField({
    required this.controller,
    required this.tone,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final AppAmountFieldTone tone;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<AppAmountField> createState() => _AppAmountFieldState();
}

class _AppAmountFieldState extends State<AppAmountField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(_handleStateChanged);
    widget.controller.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleStateChanged);
    _focusNode
      ..removeListener(_handleStateChanged)
      ..dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    final bool hasError = widget.errorText != null;
    final bool filled = widget.controller.text.trim().isNotEmpty;

    final ({Color surface, Color border, Color ink, Color hint, Color ring})
        colors = switch (widget.tone) {
      AppAmountFieldTone.expense => (
        surface: AppColors.expenseSoft,
        border: const Color(0xFFE9C2B2),
        ink: AppColors.expense,
        hint: AppColors.expense.withValues(alpha: 0.38),
        ring: AppColors.expense.withValues(alpha: 0.16),
      ),
      AppAmountFieldTone.income => (
        surface: AppColors.incomeSoft,
        border: const Color(0xFFB9D6BF),
        ink: AppColors.income,
        hint: AppColors.income.withValues(alpha: 0.38),
        ring: AppColors.income.withValues(alpha: 0.16),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppEasing.standard,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: hasError
                  ? AppColors.expense
                  : focused
                  ? colors.ink
                  : colors.border,
              width: focused || hasError ? 1.5 : 1,
            ),
            boxShadow: <BoxShadow>[
              ...AppShadows.sm,
              if (focused && !hasError)
                BoxShadow(
                  color: colors.ring,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'AMOUNT · GBP',
                style: AppTypography.eye.copyWith(
                  color: filled
                      ? colors.ink.withValues(alpha: 0.9)
                      : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 6),
                    child: Text(
                      '£',
                      style: AppTypography.numLg.copyWith(
                        color: filled ? colors.ink : colors.hint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9\.,]'),
                        ),
                      ],
                      cursorColor: colors.ink,
                      style: AppTypography.numXxl.copyWith(
                        color: colors.ink,
                        height: 0.98,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: AppTypography.numXxl.copyWith(
                          color: colors.hint,
                          height: 0.98,
                        ),
                      ),
                      onChanged: widget.onChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                focused
                    ? 'Amount first. Details follow below.'
                    : 'Use the numeric keyboard for a fast entry.',
                style: AppTypography.meta.copyWith(
                  color: filled ? colors.ink.withValues(alpha: 0.72) : null,
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.errorText!,
              style: AppTypography.meta.copyWith(color: AppColors.expense),
            ),
          ),
        ],
      ],
    );
  }
}
