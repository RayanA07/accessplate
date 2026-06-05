import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'section_card.dart';

class HomeTabHeader extends StatelessWidget {
  const HomeTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.eyebrow,
    this.trailing,
    this.tintColor,
    this.cardTintColor,
    this.fillColor,
    this.iconBackgroundColor,
    this.iconBorderColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? eyebrow;
  final Widget? trailing;
  final Color? tintColor;
  final Color? cardTintColor;
  final Color? fillColor;
  final Color? iconBackgroundColor;
  final Color? iconBorderColor;

  @override
  Widget build(BuildContext context) {
    final iconTint = tintColor ?? NihPalette.primary;
    return SectionCard(
      tintColor: cardTintColor ?? iconTint.withValues(alpha: 0.18),
      fillColor: fillColor,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: iconBackgroundColor ?? iconTint.withValues(alpha: 0.14),
              border: Border.all(
                color: iconBorderColor ?? iconTint.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(icon, color: iconTint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: iconTint,
                      letterSpacing: 0.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
