import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/engine/scoring/composite_scorer.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/user_language.dart';
import '../../copy/app_copy.dart';
import '../../providers/cache_controller.dart';
import '../../providers/profile_controller.dart';
import '../../providers/session_controller.dart';
import '../../widgets/live_grocery_settings_card.dart';
import '../../widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            container: true,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.accessLanguageTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(copy.accessLanguageSubtitle),
                  const SizedBox(height: 12),
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
                        onSelected: (_) => controller.updateLanguage(language),
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
          ),
          const SizedBox(height: 12),
          if (profile.localLogin.isConfigured) ...[
            Semantics(
              container: true,
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.choose('Local login', 'Acceso local'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy.choose(
                        'Saved on this device for ${profile.localLogin.displayName}.',
                        'Guardado en este dispositivo para ${profile.localLogin.displayName}.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(sessionControllerProvider.notifier).lock();
                        Navigator.of(context).pop();
                      },
                      child: Text(copy.choose('Lock app now', 'Bloquear ahora')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
            container: true,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Appearance', 'Apariencia'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                    children: AppThemePreference.values.map((themePreference) {
                      return ChoiceChip(
                        selected: profile.themePreference == themePreference,
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
          ),
          const SizedBox(height: 12),
          const LiveGrocerySettingsCard(),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Advanced scoring', 'Puntaje avanzado'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.choose(
                      'Most people can leave this alone. These sliders change how strongly the engine weighs nutrition, cost, and preference.',
                      'La mayoria de personas puede dejar esto igual. Estos controles cambian cuanto pesa nutricion, costo y preferencia.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeightSlider(
                    label: copy.choose('Macro alignment', 'Ajuste de macros'),
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
                    label: copy.choose('Cost pressure', 'Presion por costo'),
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
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Local cache', 'Cache local'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                        Text(
                          copy.choose(
                            'Cached foods: ${stats.cachedFoodCount}',
                            'Alimentos en cache: ${stats.cachedFoodCount}',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          copy.choose(
                            'Eligible for cleanup: ${stats.staleFoodCount}',
                            'Listos para limpieza: ${stats.staleFoodCount}',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          copy.choose(
                            'Last cleanup: ${_formatDateTime(stats.lastCleanupAt, copy)}',
                            'Ultima limpieza: ${_formatDateTime(stats.lastCleanupAt, copy)}',
                          ),
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
                      copy.choose('Run cache cleanup', 'Limpiar cache ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Profile actions', 'Acciones del perfil'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                      if (context.mounted) {
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
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      copy.choose('Reset local profile', 'Borrar perfil local'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
