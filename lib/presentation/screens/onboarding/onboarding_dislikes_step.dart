import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingDislikesStep extends ConsumerStatefulWidget {
  const OnboardingDislikesStep({super.key});

  @override
  ConsumerState<OnboardingDislikesStep> createState() =>
      _OnboardingDislikesStepState();
}

class _OnboardingDislikesStepState
    extends ConsumerState<OnboardingDislikesStep> {
  final _dislikeController = TextEditingController();

  @override
  void dispose() {
    _dislikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final copy = AppCopy(profile.constraints.access.language);

    return OnboardingStepLayout(
      title: copy.dislikesTitle,
      subtitle: copy.dislikesSubtitle,
      children: [
        OnboardingSearchField(
          controller: _dislikeController,
          hintText: copy.dislikesFieldHint,
          onSubmitted: (_) => _addDislike(preference),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.dislikesSectionLabel),
              const SizedBox(height: 12),
              if (preference.dislikedIngredients.isEmpty)
                Text(
                  copy.dislikesEmptyLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8F8F95),
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preference.dislikedIngredients.map((ingredient) {
                    return InputChip(
                      label: Text(_labelize(ingredient)),
                      onDeleted: () {
                        final next = {...preference.dislikedIngredients}
                          ..remove(ingredient);
                        ref
                            .read(profileControllerProvider.notifier)
                            .updatePreference(
                              preference.copyWith(dislikedIngredients: next),
                            );
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _addDislike(preference),
                  child: Text(copy.dislikesAddButton),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addDislike(PreferenceConstraints preference) {
    final value = _dislikeController.text.trim().toLowerCase();
    if (value.isEmpty) {
      return;
    }

    final next = {...preference.dislikedIngredients, value};
    ref
        .read(profileControllerProvider.notifier)
        .updatePreference(preference.copyWith(dislikedIngredients: next));
    _dislikeController.clear();
  }

  static String _labelize(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
