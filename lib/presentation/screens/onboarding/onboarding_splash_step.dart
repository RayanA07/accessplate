import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class OnboardingSplashStep extends ConsumerWidget {
  const OnboardingSplashStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final copy = AppCopy(
      profile?.constraints.access.language ??
          UserProfile.defaults().constraints.access.language,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFF0F0F3)),
            ),
            child: Text(
              copy.choose('Welcome to', 'Bienvenido a'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF74806F),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4E7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF2E9B51),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AccessPlate',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            copy.choose(
              'Personalized healthy meal picks\nfor what you can actually reach',
              'Opciones saludables personalizadas\nsegun lo que si puedes alcanzar',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6E6E74),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 440,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -50,
                  right: -50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _GhostPhone(alignment: Alignment.centerLeft),
                      _GhostPhone(alignment: Alignment.centerRight),
                    ],
                  ),
                ),
                const _PhonePreview(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                width: index == 1 ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == 1
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFD7D7DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            borderRadius: 26,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Text(
              copy.splashLocalDataDetail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 262,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(42),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF7),
          borderRadius: BorderRadius.circular(34),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 86,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: Color(0xFF808088),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Suggested Meals',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19191D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: _PreviewMealCard(
                  title: 'Protein Cut',
                  subtitle: 'Excellent fit for your calories and protein.',
                  score: 99,
                  icon: Icons.lunch_dining_rounded,
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: _PreviewMealCard(
                  title: 'Build & Balance',
                  subtitle: 'Macro-friendly and simple to reach today.',
                  score: 97,
                  icon: Icons.local_dining_rounded,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMealCard extends StatelessWidget {
  const _PreviewMealCard({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final int score;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 38, color: const Color(0xFF2A9D50)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111114),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Color(0xFF76767E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF38C86C), width: 2.2),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38C86C),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PreviewMacro(label: 'CAL', value: '390'),
              _PreviewMacro(label: 'Protein', value: '30g'),
              _PreviewMacro(label: 'Carbs', value: '10g'),
              _PreviewMacro(label: 'Fats', value: '27g'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Access',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F9E54),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Why'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMacro extends StatelessWidget {
  const _PreviewMacro({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF16161A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF92929A),
          ),
        ),
      ],
    );
  }
}

class _GhostPhone extends StatelessWidget {
  const _GhostPhone({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.26,
      child: Transform.scale(
        scale: 0.84,
        child: Align(
          alignment: alignment,
          child: Container(
            width: 170,
            height: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }
}
