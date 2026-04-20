import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_input.dart';

class HiFiInputField extends StatelessWidget {
  const HiFiInputField({
    this.controller,
    this.label,
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
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
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
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      prefix: prefix,
      suffix: suffix,
      helper: helper,
      errorText: errorText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
}
