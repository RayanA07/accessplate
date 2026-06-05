import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum SelectionTileIndicatorStyle { radio, check }

enum SelectionTileVisualStyle { standard, prominentRadio }

class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.indicatorStyle = SelectionTileIndicatorStyle.radio,
    this.visualStyle = SelectionTileVisualStyle.standard,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final SelectionTileIndicatorStyle indicatorStyle;
  final SelectionTileVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _styleFor(theme);
    const borderRadius = BorderRadius.all(Radius.circular(28));

    return Material(
      color: style.tileColor,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: style.tileColor,
            borderRadius: borderRadius,
            border: style.border,
            boxShadow: style.shadows,
          ),
          child: Stack(
            children: [
              if (style.selectedAccentColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: style.selectedAccentWidth,
                    child: ColoredBox(color: style.selectedAccentColor!),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: style.iconColor, size: 21),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: style.titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: style.subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SelectionTileIndicator(
                      selected: selected,
                      indicatorStyle: indicatorStyle,
                      visualStyle: visualStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SelectionTileStyle _styleFor(ThemeData theme) {
    return switch (visualStyle) {
      SelectionTileVisualStyle.standard => _SelectionTileStyle(
        tileColor: selected
            ? NihPalette.secondaryLightest
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? NihPalette.secondaryLight
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
        shadows: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (selected)
            BoxShadow(
              color: NihPalette.primary.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
        ],
        iconColor: selected ? NihPalette.primary : NihPalette.base,
        titleColor: selected ? NihPalette.primaryDarker : NihPalette.base,
        subtitleColor: selected
            ? NihPalette.grayDark
            : theme.colorScheme.onSurfaceVariant,
      ),
      SelectionTileVisualStyle.prominentRadio => _SelectionTileStyle(
        tileColor: selected ? const Color(0xFFE8F5E9) : NihPalette.white,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        shadows: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        iconColor: selected ? NihPalette.primary : NihPalette.base,
        titleColor: NihPalette.base,
        subtitleColor: theme.colorScheme.onSurfaceVariant,
        selectedAccentColor: selected ? NihPalette.success : null,
        selectedAccentWidth: 4,
      ),
    };
  }
}

class _SelectionTileIndicator extends StatelessWidget {
  const _SelectionTileIndicator({
    required this.selected,
    required this.indicatorStyle,
    required this.visualStyle,
  });

  final bool selected;
  final SelectionTileIndicatorStyle indicatorStyle;
  final SelectionTileVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    if (visualStyle == SelectionTileVisualStyle.prominentRadio &&
        indicatorStyle == SelectionTileIndicatorStyle.radio) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? NihPalette.success : Colors.transparent,
          border: Border.all(
            color: selected
                ? NihPalette.success
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1 : 1.6,
          ),
        ),
      );
    }

    return Container(
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
    );
  }
}

class _SelectionTileStyle {
  const _SelectionTileStyle({
    required this.tileColor,
    required this.border,
    required this.shadows,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    this.selectedAccentColor,
    this.selectedAccentWidth = 0,
  });

  final Color tileColor;
  final BoxBorder border;
  final List<BoxShadow> shadows;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color? selectedAccentColor;
  final double selectedAccentWidth;
}
