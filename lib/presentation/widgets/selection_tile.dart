import 'package:flutter/material.dart';

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
    final tileColor = selected ? const Color(0xFFE3E3E8) : Colors.white;
    final borderColor = selected
        ? const Color(0xFFC8C8D0)
        : const Color(0xFFF0F0F3);
    final iconColor = selected
        ? const Color(0xFF16161A)
        : const Color(0xFF111111);
    final titleColor = selected
        ? const Color(0xFF17171B)
        : const Color(0xFF232326);
    final subtitleColor = selected
        ? const Color(0xFF66666E)
        : const Color(0xFF919197);

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
                color: Color(0x0F000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
              if (selected)
                const BoxShadow(
                  color: Color(0x14000000),
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
                        ? const Color(0xFFEDEDEF)
                        : const Color(0xFFF3F3F5),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFD7D7DC)
                          : const Color(0xFFEAEAF0),
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
                                  ? const Color(0xFFB0B0B7)
                                  : const Color(0xFFD2D2D8),
                              shape: BoxShape.circle,
                            ),
                          )
                        : Icon(
                            Icons.check_rounded,
                            color: selected
                                ? const Color(0xFFB0B0B7)
                                : const Color(0xFFD2D2D8),
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
