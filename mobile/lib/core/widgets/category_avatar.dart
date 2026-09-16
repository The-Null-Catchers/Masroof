import 'package:flutter/material.dart';

import 'icon_catalog.dart';

class ColoredIconAvatar extends StatelessWidget {
  const ColoredIconAvatar({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: tint, size: size * 0.52),
    );
  }

  factory ColoredIconAvatar.named(String? iconName, String? hex, {double size = 40}) =>
      ColoredIconAvatar(icon: IconCatalog.resolve(iconName), color: parseHexColor(hex), size: size);
}
