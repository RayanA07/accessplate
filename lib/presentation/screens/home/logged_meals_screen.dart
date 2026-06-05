import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/engine/government_nutrition_guidance.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/home_tab_header.dart';
import '../../widgets/section_card.dart';

class LoggedMealsScreen extends ConsumerWidget {
  const LoggedMealsScreen({super.key});

  static const _guidance = GovernmentNutritionGuidance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);
    final todayIntake = _effectiveIntake(profile);
    final dailyTargets = _guidance.dailyTargetsFor(
      profile.constraints.demographics,
    );
    final loggedMeals =
        profile.constraints.loggedMeals
            .where((entry) => _isToday(entry.loggedAt))
            .toList()
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final lastLogged = loggedMeals.isEmpty ? null : loggedMeals.first.loggedAt;
    final remainingCalories =
        (dailyTargets.calories - (todayIntake['calories_kcal'] ?? 0)).clamp(
          0,
          dailyTargets.calories,
        );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NihPalette.lightContentBackground,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    HomeTabHeader(
                      eyebrow: copy.choose('Today only', 'Solo hoy'),
                      title: copy.choose('Today\'s log', 'Registro de hoy'),
                      subtitle: copy.choose(
                        'See what you already tracked today and how much room is left before your daily target.',
                        'Mira lo que ya registraste hoy y cuanto espacio queda antes de tu meta diaria.',
                      ),
                      icon: Icons.receipt_long_rounded,
                      tintColor: NihPalette.primary,
                      cardTintColor: Colors.transparent,
                      fillColor: NihPalette.white,
                      iconBackgroundColor: const Color(0xFFF5F0E8),
                      iconBorderColor: NihPalette.borderSoft,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _LoggedStatCard(
                            label: copy.choose(
                              'Meals logged',
                              'Comidas guardadas',
                            ),
                            value: '${loggedMeals.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LoggedStatCard(
                            label: copy.choose(
                              'Calories left',
                              'Calorias restantes',
                            ),
                            value:
                                '${remainingCalories.toStringAsFixed(0)} kcal',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LoggedStatCard(
                            label: copy.choose('Last added', 'Ultima vez'),
                            value: _formatTime(lastLogged, copy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      tintColor: NihPalette.secondaryLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.choose('Today totals', 'Totales de hoy'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            copy.choose(
                              'These numbers update every time you log a recommended meal.',
                              'Estos numeros cambian cada vez que registras una comida recomendada.',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _TotalPill(
                                label: copy.caloriesLabel,
                                value:
                                    '${(todayIntake['calories_kcal'] ?? 0).toStringAsFixed(0)} kcal',
                              ),
                              _TotalPill(
                                label: copy.proteinLabel,
                                value:
                                    '${(todayIntake['protein_g'] ?? 0).toStringAsFixed(0)} g',
                              ),
                              _TotalPill(
                                label: copy.carbsLabel,
                                value:
                                    '${(todayIntake['carbs_g'] ?? 0).toStringAsFixed(0)} g',
                              ),
                              _TotalPill(
                                label: copy.fatLabel,
                                value:
                                    '${(todayIntake['fat_g'] ?? 0).toStringAsFixed(0)} g',
                              ),
                              _TotalPill(
                                label: copy.choose('Fiber', 'Fibra'),
                                value:
                                    '${(todayIntake['fiber_g'] ?? 0).toStringAsFixed(0)} g',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.choose('Log times', 'Horas del registro'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          if (loggedMeals.isEmpty)
                            Text(
                              copy.choose(
                                'Nothing has been logged yet today. Use Log meal on a meal card to start your daily totals.',
                                'Todavia no se ha registrado nada hoy. Usa Registrar comida en una tarjeta para empezar tus totales diarios.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < loggedMeals.length;
                                  index++
                                ) ...[
                                  _TimelineEntry(
                                    label: loggedMeals[index].mealName,
                                    value: _formatTime(
                                      loggedMeals[index].loggedAt,
                                      copy,
                                    ),
                                  ),
                                  if (index < loggedMeals.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (loggedMeals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  child: _LoggedEmptyState(copy: copy),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                sliver: SliverToBoxAdapter(
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.choose(
                            'Need a fresh start?',
                            'Necesitas empezar otra vez?',
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.choose(
                            'Reset today if you want to clear the current daily totals and log the day again from zero.',
                            'Reinicia hoy si quieres borrar los totales del dia y registrar todo otra vez desde cero.',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: controller.resetDailyTracking,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text(
                            copy.choose('Reset today', 'Reiniciar hoy'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _effectiveIntake(UserProfile profile) {
    final intakeDate = profile.constraints.todayIntakeDate;
    if (intakeDate == null || !_isToday(intakeDate)) {
      return const <String, double>{};
    }
    return profile.constraints.todayIntake;
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  String _formatTime(DateTime? value, AppCopy copy) {
    if (value == null) {
      return copy.choose('Nothing yet', 'Todavia nada');
    }
    final local = value.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _LoggedStatCard extends StatelessWidget {
  const _LoggedStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NihPalette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NihPalette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: NihPalette.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _LoggedEmptyState extends StatelessWidget {
  const _LoggedEmptyState({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.flatware_rounded,
            size: 64,
            color: Color(0xFF9A9A9A),
          ),
          const SizedBox(height: 14),
          Text(
            copy.choose('Nothing logged yet today', 'Todavia no hay nada hoy'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF555555),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            copy.choose(
              'Tap Log meal on any suggestion to start tracking.',
              'Toca Registrar comida en cualquier sugerencia para empezar.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: const Color(0xFF9B9B9B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
