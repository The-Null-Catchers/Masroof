import 'package:flutter/material.dart';

/// Masroof brand mark (wallet + coin), optionally with the wordmark.
class MasroofLogo extends StatelessWidget {
  const MasroofLogo({super.key, this.size = 56, this.showWordmark = false, this.wordmarkColor});

  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/branding/mark.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: showWordmark ? null : 'Masroof',
    );
    if (!showWordmark) return mark;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.18),
        Text(
          isArabic ? 'مصروف' : 'Masroof',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, color: wordmarkColor, letterSpacing: isArabic ? 0 : 0.2),
        ),
      ],
    );
  }
}
