import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 31,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.32,
            color: Color(0xFF8F8F95),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF98989D),
            size: 24,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Color(0xFFF1F1F3)),
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A1A1A),
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
  });

  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

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
                    ? const Color(0xFF111111)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                labelBuilder(option),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: option == value
                      ? Colors.white
                      : const Color(0xFF5E5E64),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Color(0xFF8E8E93),
      ),
    );
  }
}
