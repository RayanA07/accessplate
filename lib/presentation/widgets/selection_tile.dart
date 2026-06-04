import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum SelectionTileIndicatorStyle { radio, check }

class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.indicatorStyle = SelectionTileIndicatorStyle.radio,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final SelectionTileIndicatorStyle indicatorStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = selected
        ? NihPalette.secondaryLightest
        : Theme.of(context).colorScheme.surface;
    final borderColor = selected
        ? NihPalette.secondaryLight
        : Theme.of(context).colorScheme.outlineVariant;
    final iconColor = selected ? NihPalette.primary : NihPalette.base;
    final titleColor = selected ? NihPalette.primaryDarker : NihPalette.base;
    final subtitleColor = selected
        ? NihPalette.grayDark
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
              if (selected)
                BoxShadow(
                  color: NihPalette.primary.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 21),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? NihPalette.primary.withValues(alpha: 0.10)
                        : NihPalette.sand,
                    border: Border.all(
                      color: selected
                          ? NihPalette.primary.withValues(alpha: 0.22)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Center(
                    child: indicatorStyle == SelectionTileIndicatorStyle.radio
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: selected ? 8 : 10,
                            height: selected ? 8 : 10,
                            decoration: BoxDecoration(
                              color: selected
                                  ? NihPalette.primary
                                  : NihPalette.grayDark.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          )
                        : Icon(
                            Icons.check_rounded,
                            color: selected
                                ? NihPalette.primary
                                : NihPalette.grayDark.withValues(alpha: 0.45),
                            size: 16,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
