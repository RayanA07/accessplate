import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.topSpacing = 34,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            height: 1.06,
            letterSpacing: -0.9,
            color: NihPalette.base,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.46,
            color: NihPalette.grayDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: topSpacing),
        ...children,
      ],
    );
  }
}

class OnboardingSearchField extends StatelessWidget {
  const OnboardingSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: NihPalette.grayDark,
            size: 24,
          ),
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: NihPalette.grayDark,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: NihPalette.warmSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(color: NihPalette.borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(color: NihPalette.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: NihPalette.primary, width: 1.3),
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: NihPalette.base,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OnboardingSegmentedControl<T> extends StatelessWidget {
  const OnboardingSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.minOptionHeight = 40,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final double minOptionHeight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: option == value
                    ? NihPalette.primary
                    : NihPalette.secondaryLightest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: option == value
                      ? NihPalette.primary
                      : NihPalette.secondaryLight,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minOptionHeight),
                child: Center(
                  child: Text(
                    labelBuilder(option),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: option == value
                          ? Colors.white
                          : NihPalette.primaryDarker,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class OnboardingMetaLabel extends StatelessWidget {
  const OnboardingMetaLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.14,
        color: NihPalette.grayDark,
      ),
    );
  }
}
