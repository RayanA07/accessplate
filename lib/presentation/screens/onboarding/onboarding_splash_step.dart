import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
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
              color: NihPalette.secondaryLightest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDCE8CF)),
            ),
            child: Text(
              copy.choose('Welcome to', 'Bienvenido a'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D7150),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3E7),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF2E9B51),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AccessPlate',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              copy.choose(
                'Personalized healthy meal picks\nfor what you can actually reach',
                'Opciones saludables personalizadas\nsegun lo que si puedes alcanzar',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4E5058),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 18),
          Column(
            children: [
              _FeatureRow(
                key: const ValueKey('splash-feature-offline'),
                icon: Icons.download_done_rounded,
                label: copy.splashLocalFirstTitle,
                detail: copy.splashLocalFirstDetail,
              ),
              const SizedBox(height: 10),
              _FeatureRow(
                key: const ValueKey('splash-feature-explainable'),
                icon: Icons.fact_check_rounded,
                label: copy.splashExplainableTitle,
                detail: copy.splashExplainableDetail,
              ),
              const SizedBox(height: 10),
              _FeatureRow(
                key: const ValueKey('splash-feature-budget'),
                icon: Icons.payments_rounded,
                label: copy.splashAccessTitle,
                detail: copy.splashAccessDetail,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RecommendationMockCard(copy: copy),
          const SizedBox(height: 16),
          SectionCard(
            borderRadius: 26,
            tintColor: NihPalette.secondaryLight,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF5D7150),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.splashLocalDataTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        copy.splashLocalDataDetail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.42,
                          color: const Color(0xFF555761),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E0D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: NihPalette.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: NihPalette.base,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F717A),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationMockCard extends StatelessWidget {
  const _RecommendationMockCard({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('splash-recommendation-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDF9F0), Color(0xFFF4EFE2), Color(0xFFF1F6EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE6DDCC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE6DDCC)),
                ),
                child: Text(
                  copy.choose(
                    'Sample recommendation',
                    'Recomendacion de muestra',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B6E74),
                  ),
                ),
              ),
              const Spacer(),
              const _ScoreBadge(score: 96),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.ramen_dining_rounded,
                  size: 38,
                  color: Color(0xFF2E9B51),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.choose(
                        'Veggie rice bowl',
                        'Tazon de arroz con verduras',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF17181C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      copy.choose(
                        'Strong protein fit, easy pantry overlap, and realistic today.',
                        'Buen ajuste de proteina, usa despensa y sigue siendo realista hoy.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF676A72),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7E1D4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: Color(0xFF2E9B51),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      copy.choose('Store: Save A Lot', 'Tienda: Save A Lot'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: NihPalette.base,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  copy.choose('Buy list preview', 'Vista previa de compra'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6F717A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreviewTag(
                      label: copy.choose('brown rice', 'arroz integral'),
                    ),
                    _PreviewTag(
                      label: copy.choose('black beans', 'frijoles negros'),
                    ),
                    _PreviewTag(
                      label: copy.choose(
                        'frozen spinach',
                        'espinaca congelada',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E9B51),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F626A),
        ),
      ),
    );
  }
}
