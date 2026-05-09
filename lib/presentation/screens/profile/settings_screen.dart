import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/engine/scoring/composite_scorer.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
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
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    if (!_didInitWeights) {
      _weights = profile.scoringWeights;
      _didInitWeights = true;
    }
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppThemePreference.values.map((themePreference) {
                    return ChoiceChip(
                      selected: profile.themePreference == themePreference,
                      label: Text(themePreference.name),
                      onSelected: (_) {
                        controller.updateThemePreference(themePreference);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composite score weights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('Adjust how strongly the engine favors nutrition fit, penalties, cost, and preference.'),
                const SizedBox(height: 12),
                _WeightSlider(
                  label: 'Macro alignment',
                  value: _weights.macro,
                  onChanged: (value) => setState(() {
                    _weights = _weights.copyWith(macro: value);
                  }),
                ),
                _WeightSlider(
                  label: 'Micronutrients',
                  value: _weights.micro,
                  onChanged: (value) => setState(() {
                    _weights = _weights.copyWith(micro: value);
                  }),
                ),
                _WeightSlider(
                  label: 'Penalty strength',
                  value: _weights.penalty,
                  onChanged: (value) => setState(() {
                    _weights = _weights.copyWith(penalty: value);
                  }),
                ),
                _WeightSlider(
                  label: 'Cost pressure',
                  value: _weights.cost,
                  onChanged: (value) => setState(() {
                    _weights = _weights.copyWith(cost: value);
                  }),
                ),
                _WeightSlider(
                  label: 'Preference bonus',
                  value: _weights.preference,
                  onChanged: (value) => setState(() {
                    _weights = _weights.copyWith(preference: value);
                  }),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    controller.updateWeights(_weights);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Weights saved')),
                    );
                  },
                  child: const Text('Save weight profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
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
                  child: const Text('Reopen onboarding'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    await controller.resetProfile();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Reset local profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
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
