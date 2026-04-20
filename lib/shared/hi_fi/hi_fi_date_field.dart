import 'package:flutter/material.dart';

import '../widgets/app_date_field.dart';

class HiFiDateField extends StatelessWidget {
  const HiFiDateField({
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
    return AppDateField(
      label: label,
      value: value,
      onTap: onTap,
      showTodayPill: showTodayPill,
    );
  }
}
