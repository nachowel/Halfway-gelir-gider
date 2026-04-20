import 'package:flutter/material.dart';

import '../widgets/app_amount_field.dart';

enum HiFiAmountFieldTone { expense, income }

extension on HiFiAmountFieldTone {
  AppAmountFieldTone get asAppTone {
    switch (this) {
      case HiFiAmountFieldTone.expense:
        return AppAmountFieldTone.expense;
      case HiFiAmountFieldTone.income:
        return AppAmountFieldTone.income;
    }
  }
}

class HiFiAmountField extends StatelessWidget {
  const HiFiAmountField({
    required this.controller,
    required this.tone,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final HiFiAmountFieldTone tone;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppAmountField(
      controller: controller,
      tone: tone.asAppTone,
      errorText: errorText,
      autofocus: autofocus,
      onChanged: onChanged,
    );
  }
}
