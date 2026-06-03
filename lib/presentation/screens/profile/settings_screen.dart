import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/engine/scoring/composite_scorer.dart';
import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/user_language.dart';
import '../../copy/app_copy.dart';
import '../../providers/cache_controller.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/live_grocery_settings_card.dart';
import '../../widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late CompositeWeights _weights;
  bool _didInitWeights = false;

  @override
  void initState() {
    super.initState();
    _weights = const CompositeWeights();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final cacheStatsAsync = ref.watch(cacheControllerProvider);
    if (!_didInitWeights) {
      _weights = profile.scoringWeights;
      _didInitWeights = true;
    }
    final copy = AppCopy(profile.constraints.access.language);
    final normalizedWeights = _weights.normalized();
    final controller = ref.read(profileControllerProvider.notifier);

    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NihPalette.lightContentBackground,
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.settingsTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _AvatarBadge(name: profile.localLogin.displayName),
                  ],
                ),
                const SizedBox(height: 18),
                _ProfileSummaryCard(profile: profile, copy: copy),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.accessLanguageTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(copy.accessLanguageSubtitle),
                      const SizedBox(height: 14),
                      Text(
                        copy.languageSettingLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: UserLanguage.values.map((language) {
                          return ChoiceChip(
                            selected:
                                profile.constraints.access.language == language,
                            label: Text(copy.languageChoiceLabel(language)),
                            onSelected: (_) =>
                                controller.updateLanguage(language),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: profile.constraints.access.plainLanguage,
                        contentPadding: EdgeInsets.zero,
                        title: Text(copy.plainLanguageSettingTitle),
                        subtitle: Text(copy.plainLanguageSettingSubtitle),
                        onChanged: controller.updatePlainLanguage,
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
                        copy.choose('Appearance', 'Apariencia'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.choose(
                          'Visual settings only. This does not change your food-access logic.',
                          'Solo cambia lo visual. No cambia la logica de acceso a comida.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppThemePreference.values.map((
                          themePreference,
                        ) {
                          return ChoiceChip(
                            selected:
                                profile.themePreference == themePreference,
                            label: Text(_labelize(themePreference.name, copy)),
                            onSelected: (_) {
                              controller.updateThemePreference(themePreference);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const LiveGrocerySettingsCard(),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.choose('Advanced scoring', 'Puntaje avanzado'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.choose(
                          'These sliders rebalance how strongly the engine weighs nutrition, cost, and preference.',
                          'Estos controles cambian cuanto pesa nutricion, costo y preferencia.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _WeightSlider(
                        label: copy.choose(
                          'Macro alignment',
                          'Ajuste de macros',
                        ),
                        value: _weights.macro,
                        displayPercent: normalizedWeights.macro,
                        onChanged: (value) => setState(() {
                          _weights = _weights.copyWith(macro: value);
                        }),
                      ),
                      _WeightSlider(
                        label: copy.choose('Micronutrients', 'Micronutrientes'),
                        value: _weights.micro,
                        displayPercent: normalizedWeights.micro,
                        onChanged: (value) => setState(() {
                          _weights = _weights.copyWith(micro: value);
                        }),
                      ),
                      _WeightSlider(
                        label: copy.choose(
                          'Penalty strength',
                          'Fuerza de penalidad',
                        ),
                        value: _weights.penalty,
                        displayPercent: normalizedWeights.penalty,
                        onChanged: (value) => setState(() {
                          _weights = _weights.copyWith(penalty: value);
                        }),
                      ),
                      _WeightSlider(
                        label: copy.choose(
                          'Cost pressure',
                          'Presion por costo',
                        ),
                        value: _weights.cost,
                        displayPercent: normalizedWeights.cost,
                        onChanged: (value) => setState(() {
                          _weights = _weights.copyWith(cost: value);
                        }),
                      ),
                      _WeightSlider(
                        label: copy.choose(
                          'Preference bonus',
                          'Bono por preferencia',
                        ),
                        value: _weights.preference,
                        displayPercent: normalizedWeights.preference,
                        onChanged: (value) => setState(() {
                          _weights = _weights.copyWith(preference: value);
                        }),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          controller.updateWeights(_weights);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                copy.choose(
                                  'Advanced scoring saved',
                                  'Puntaje avanzado guardado',
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          copy.choose(
                            'Save advanced scoring',
                            'Guardar puntaje avanzado',
                          ),
                        ),
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
                        copy.choose('Local cache', 'Cache local'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.choose(
                          'This app keeps foods in a local cache and cleans up entries that go unused for 90 days.',
                          'Esta app guarda alimentos en un cache local y limpia entradas sin uso por 90 dias.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      cacheStatsAsync.when(
                        data: (stats) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryLine(
                              label: copy.choose(
                                'Cached foods',
                                'Alimentos en cache',
                              ),
                              value: '${stats.cachedFoodCount}',
                            ),
                            const SizedBox(height: 6),
                            _SummaryLine(
                              label: copy.choose(
                                'Eligible for cleanup',
                                'Listos para limpieza',
                              ),
                              value: '${stats.staleFoodCount}',
                            ),
                            const SizedBox(height: 6),
                            _SummaryLine(
                              label: copy.choose(
                                'Last cleanup',
                                'Ultima limpieza',
                              ),
                              value: _formatDateTime(stats.lastCleanupAt, copy),
                            ),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => Text(
                          copy.choose(
                            'Cache stats unavailable: $error',
                            'No se pudieron cargar los datos del cache: $error',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () async {
                          final removed = await ref
                              .read(cacheControllerProvider.notifier)
                              .runCleanup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  removed == 0
                                      ? copy.choose(
                                          'No stale cache entries were removed.',
                                          'No se quito ninguna entrada vieja del cache.',
                                        )
                                      : copy.choose(
                                          'Removed $removed stale cache entr${removed == 1 ? 'y' : 'ies'}.',
                                          'Se quitaron $removed entradas viejas del cache.',
                                        ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          copy.choose(
                            'Run cache cleanup',
                            'Limpiar cache ahora',
                          ),
                        ),
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
                        copy.choose('Profile actions', 'Acciones del perfil'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.choose(
                          'Use these if you want to walk through setup again or clear this device only.',
                          'Usa esto si quieres volver a hacer la configuracion o borrar solo este dispositivo.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          await controller.reopenOnboarding();
                          if (context.mounted && !widget.embedded) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          copy.choose(
                            'Reopen onboarding',
                            'Abrir registro otra vez',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () async {
                          await controller.resetProfile();
                          if (context.mounted && !widget.embedded) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          copy.choose(
                            'Reset local profile',
                            'Borrar perfil local',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widget.embedded ? content : Scaffold(body: content);
  }

  String _labelize(String value, AppCopy copy) {
    return switch (value) {
      'system' => copy.choose('System', 'Sistema'),
      'light' => copy.choose('Light', 'Claro'),
      'dark' => copy.choose('Dark', 'Oscuro'),
      _ => value[0].toUpperCase() + value.substring(1),
    };
  }

  String _formatDateTime(DateTime? value, AppCopy copy) {
    if (value == null) {
      return copy.choose('Not yet', 'Todavia no');
    }

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF25396B), Color(0xFF0E1C3F), Color(0xFF142B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile, required this.copy});

  final UserProfile profile;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final demographics = profile.constraints.demographics;
    final name = profile.localLogin.displayName.trim();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.choose('Profile', 'Perfil'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          _SummaryLine(
            label: copy.choose('Age', 'Edad'),
            value: '${demographics.ageYears}',
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: copy.choose('Height', 'Altura'),
            value: _formatHeight(demographics),
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: copy.choose('Weight', 'Peso'),
            value: _formatWeight(demographics),
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: copy.choose('Activity', 'Actividad'),
            value: _activityLabel(copy, demographics.activityLevel),
          ),
        ],
      ),
    );
  }

  String _formatHeight(Demographics demographics) {
    final heightCm = demographics.heightCm;
    if (heightCm == null) {
      return '--';
    }
    final totalInches = (heightCm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet\'$inches"';
  }

  String _formatWeight(Demographics demographics) {
    final weightKg = demographics.weightKg;
    if (weightKg == null) {
      return '--';
    }
    final pounds = weightKg * 2.20462;
    return '${pounds.toStringAsFixed(1)} lbs';
  }

  String _activityLabel(AppCopy copy, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => copy.choose('Inactive', 'Inactiva'),
      ActivityLevel.light => copy.choose('Low active', 'Poco activa'),
      ActivityLevel.moderate => copy.choose('Active', 'Activa'),
      ActivityLevel.active => copy.choose('High active', 'Muy activa'),
      ActivityLevel.veryActive => copy.choose(
        'Very active',
        'Actividad muy alta',
      ),
    };
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.displayPercent,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double displayPercent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${(displayPercent * 100).round()}%'),
        Slider(
          min: 0.05,
          max: 0.5,
          divisions: 45,
          value: value.clamp(0.05, 0.5),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
