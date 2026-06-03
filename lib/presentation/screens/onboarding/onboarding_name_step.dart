import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingNameStep extends ConsumerStatefulWidget {
  const OnboardingNameStep({super.key});

  @override
  ConsumerState<OnboardingNameStep> createState() => _OnboardingNameStepState();
}

class _OnboardingNameStepState extends ConsumerState<OnboardingNameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _controller = TextEditingController(
      text: profile?.localLogin.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose('What should we\ncall you?', 'Como te\nllamamos?'),
      subtitle: copy.choose(
        'This stays on your device and personalizes your profile summary.',
        'Esto se queda en tu dispositivo y personaliza tu perfil.',
      ),
      topSpacing: 58,
      children: [
        SectionCard(
          borderRadius: 32,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: copy.choose('Name', 'Nombre'),
                  hintText: copy.choose('Enter your name', 'Escribe tu nombre'),
                ),
                onChanged: controller.updateDisplayName,
              ),
              const SizedBox(height: 12),
              Text(
                copy.choose(
                  'You can change this later from settings.',
                  'Lo puedes cambiar despues desde ajustes.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
