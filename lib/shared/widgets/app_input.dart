import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    this.controller,
    this.label,
    this.labelStyle,
    this.hint,
    this.prefix,
    this.suffix,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.fillColor,
    this.containerPadding,
    this.inputPadding,
    this.enabledBorderWidth = 1,
    this.focusedBorderWidth = 1.5,
    this.focusGlowOpacity = 0.14,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final TextStyle? labelStyle;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? fillColor;
  final EdgeInsetsGeometry? containerPadding;
  final EdgeInsetsGeometry? inputPadding;
  final double enabledBorderWidth;
  final double focusedBorderWidth;
  final double focusGlowOpacity;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode;
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;
    final Color borderColor = hasError
        ? AppColors.expense
        : _focused
        ? AppColors.brand
        : AppColors.border;
    final List<BoxShadow> focusRing = _focused || hasError
        ? <BoxShadow>[
            BoxShadow(
              color: (hasError ? AppColors.expense : AppColors.brand)
                  .withValues(alpha: widget.focusGlowOpacity),
              blurRadius: 0,
              spreadRadius: 3,
            ),
          ]
        : const <BoxShadow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(widget.label!, style: widget.labelStyle ?? AppTypography.lbl),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppEasing.standard,
          decoration: BoxDecoration(
            color: widget.fillColor ?? Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: borderColor,
              width: _focused || hasError
                  ? widget.focusedBorderWidth
                  : widget.enabledBorderWidth,
            ),
            boxShadow: focusRing,
          ),
          padding:
              widget.containerPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.prefix != null) ...<Widget>[
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.inkSoft,
                    size: 18,
                  ),
                  child: widget.prefix!,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  obscureText: widget.obscureText,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  minLines: widget.minLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                  cursorColor: AppColors.brand,
                  style: AppTypography.input,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    contentPadding:
                        widget.inputPadding ??
                        const EdgeInsets.symmetric(vertical: 12),
                    hintText: widget.hint,
                    hintStyle: AppTypography.input.copyWith(
                      color: AppColors.inkFade,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) ...<Widget>[
                const SizedBox(width: 10),
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.inkSoft,
                    size: 18,
                  ),
                  child: widget.suffix!,
                ),
              ],
            ],
          ),
        ),
        if (widget.helper != null || hasError) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.errorText ?? widget.helper!,
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
