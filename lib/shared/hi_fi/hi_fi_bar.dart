import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Progress bar from hi-fi `.bar` family. 6px height, pill, gradient fill.
enum HiFiBarTone { ink, brand, income, expense, amber }

class HiFiBar extends StatelessWidget {
  const HiFiBar({
    required this.value,
    this.tone = HiFiBarTone.ink,
    this.height = 6,
    super.key,
  });

  final double value; // 0..1
  final HiFiBarTone tone;
  final double height;

  LinearGradient? get _gradient {
    switch (tone) {
      case HiFiBarTone.ink:
        return null;
      case HiFiBarTone.brand:
        return AppGradients.barBrand;
      case HiFiBarTone.income:
        return AppGradients.barIncome;
      case HiFiBarTone.expense:
        return AppGradients.barExpense;
      case HiFiBarTone.amber:
        return AppGradients.barAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 1.0);
    final BorderRadius radius = BorderRadius.circular(height);
    final Color glowColor = switch (tone) {
      HiFiBarTone.brand => const Color(0xFF2FAF8F),
      HiFiBarTone.income => AppColors.barIncomeB,
      HiFiBarTone.expense => AppColors.barExpenseB,
      HiFiBarTone.amber => AppColors.barAmberB,
      HiFiBarTone.ink => AppColors.ink,
    };

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFFE6DDC8),
        border: Border.all(
          color: const Color(0xFFF7F0E1).withValues(alpha: 0.9),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x22FFFFFF), Color(0x08A88F67)],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        _gradient ??
                        const LinearGradient(
                          colors: <Color>[AppColors.ink, Color(0xFF304346)],
                        ),
                    borderRadius: radius,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.30),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x36FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color(0x00FFFFFF),
                        Color(0x30FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
