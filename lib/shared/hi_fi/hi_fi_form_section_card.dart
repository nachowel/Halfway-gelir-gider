import 'package:flutter/material.dart';

import '../widgets/app_form_section_card.dart';

class HiFiFormSectionCard extends StatelessWidget {
  const HiFiFormSectionCard({
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
    return AppFormSectionCard(
      label: label,
      trailing: trailing,
      helper: helper,
      errorText: errorText,
      onTap: onTap,
      child: child,
    );
  }
}
