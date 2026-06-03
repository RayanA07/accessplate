import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class LoggedMealsScreen extends ConsumerWidget {
  const LoggedMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);
    final todayIntake = _effectiveIntake(profile);
    final loggedTimes =
        profile.constraints.recentlyActed.values.where(_isToday).toList()
          ..sort((a, b) => b.compareTo(a));
    final loggedCount = loggedTimes.length;
    final lastLogged = loggedTimes.isEmpty ? null : loggedTimes.first;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NihPalette.lightContentBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Text(
              copy.choose('Logged today', 'Registrado hoy'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              copy.choose(
                'This tab is for today only: what you tracked, when you tracked it, and whether you want to reset the day.',
                'Esta pantalla es solo para hoy: que registraste, cuando lo registraste y si quieres reiniciar el dia.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _LoggedStatCard(
                  label: copy.choose('Meals tracked', 'Comidas guardadas'),
                  value: '$loggedCount',
                ),
                _LoggedStatCard(
                  label: copy.choose('Calories logged', 'Calorias guardadas'),
                  value:
                      '${(todayIntake['calories_kcal'] ?? 0).toStringAsFixed(0)} kcal',
                ),
                _LoggedStatCard(
                  label: copy.choose('Last added', 'Ultima vez'),
                  value: _formatTime(lastLogged, copy),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
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
                    copy.choose('Daily log controls', 'Controles del dia'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.choose(
                      'Use this when you want to clear today\'s tracked meals and start the day over.',
                      'Usa esto cuando quieras borrar lo registrado hoy y empezar otra vez.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: controller.resetDailyTracking,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(copy.choose('Reset today', 'Reiniciar hoy')),
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
                    copy.choose('How logging works', 'Como funciona'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.choose(
                      'Use "Log meal" on a recommendation card to update this screen. AccessPlate stores nutrition totals for the day here, not a full long-term meal journal.',
                      'Usa "Registrar comida" en una recomendacion para actualizar esta pantalla. Aqui AccessPlate guarda los totales del dia, no un historial largo de comidas.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
    return SizedBox(
      width: 118,
      child: SectionCard(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8ED)),
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
