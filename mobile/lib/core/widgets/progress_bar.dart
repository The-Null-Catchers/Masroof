import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ProgressTone { brand, onTrack, warning, exceeded }

ProgressTone toneForStatus(String status) => switch (status) {
  'exceeded' => ProgressTone.exceeded,
  'warning' => ProgressTone.warning,
  _ => ProgressTone.onTrack,
};

/// Rounded progress bar that fills from the reading start (mirrors in RTL),
/// with an optional marker for the expected pace.
class MoneyProgressBar extends StatelessWidget {
  const MoneyProgressBar({
    super.key,
    required this.percent,
    this.tone = ProgressTone.brand,
    this.marker,
    this.label,
    this.height = 8,
  });

  final double percent;
  final ProgressTone tone;
  final double? marker;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final color = switch (tone) {
      ProgressTone.brand => theme.colorScheme.primary,
      ProgressTone.onTrack => colors.income,
      ProgressTone.warning => AppColors.gold,
      ProgressTone.exceeded => colors.expense,
    };
    final value = (percent / 100).clamp(0.0, 1.0);

    return Semantics(
      label: label,
      value: '${percent.round()}%',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * value,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height)),
                ),
              ),
              if (marker != null && marker! > 0 && marker! < 100)
                PositionedDirectional(
                  start: constraints.maxWidth * marker! / 100,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: ColoredBox(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
