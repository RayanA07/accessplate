import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../providers/session_controller.dart';
import '../../widgets/section_card.dart';

class LocalLoginScreen extends ConsumerStatefulWidget {
  const LocalLoginScreen({super.key, required this.setupMode});

  final bool setupMode;

  @override
  ConsumerState<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends ConsumerState<LocalLoginScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _obscurePin = true;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final localLogin = profile.localLogin;
    if (!widget.setupMode && _nameController.text.isEmpty) {
      _nameController.text = localLogin.displayName;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: NihPalette.lightBackground,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: SectionCard(
                    tintColor: NihPalette.secondaryLight,
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.setupMode
                              ? copy.choose(
                                  'Set up your local login',
                                  'Configura tu acceso local',
                                )
                              : copy.choose(
                                  'Unlock AccessPlate',
                                  'Desbloquea AccessPlate',
                                ),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.setupMode
                              ? copy.choose(
                                  'This stays on this device only. Use a name and a 4-digit PIN so the app opens to your saved profile next time.',
                                  'Esto se queda solo en este dispositivo. Usa un nombre y un PIN de 4 digitos para abrir tu perfil guardado la proxima vez.',
                                )
                              : copy.choose(
                                  'Enter the 4-digit PIN saved on this device for ${localLogin.displayName}.',
                                  'Ingresa el PIN de 4 digitos guardado en este dispositivo para ${localLogin.displayName}.',
                                ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        if (widget.setupMode) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: copy.choose('Name', 'Nombre'),
                              helperText: copy.choose(
                                'Saved locally on this phone only.',
                                'Se guarda solo en este telefono.',
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return copy.choose(
                                  'Enter a name',
                                  'Ingresa un nombre',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: _obscurePin,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: copy.choose('4-digit PIN', 'PIN de 4 digitos'),
                            counterText: '',
                            suffixIcon: IconButton(
                              tooltip: _obscurePin
                                  ? copy.choose('Show PIN', 'Mostrar PIN')
                                  : copy.choose('Hide PIN', 'Ocultar PIN'),
                              onPressed: () {
                                setState(() {
                                  _obscurePin = !_obscurePin;
                                });
                              },
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                          validator: _validatePin,
                        ),
                        if (widget.setupMode) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPinController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePin,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: copy.choose(
                                'Confirm PIN',
                                'Confirma el PIN',
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value != _pinController.text) {
                                return copy.choose(
                                  'PINs do not match',
                                  'Los PIN no coinciden',
                                );
                              }
                              return _validatePin(value);
                            },
                          ),
                        ],
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitting ? null : () => _submit(copy),
                            child: Text(
                              _submitting
                                  ? copy.choose('Saving...', 'Guardando...')
                                  : widget.setupMode
                                  ? copy.choose('Save local login', 'Guardar acceso local')
                                  : copy.choose('Unlock', 'Desbloquear'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          copy.choose(
                            'This local login is not a cloud account and does not send profile data off-device.',
                            'Este acceso local no es una cuenta en la nube y no envia tu perfil fuera del dispositivo.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePin(String? value) {
    final pin = value ?? '';
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return (ref.read(profileControllerProvider).valueOrNull?.constraints.access.language ==
              UserProfile.defaults().constraints.access.language)
          ? '4 digits required'
          : 'Se necesitan 4 digitos';
    }
    return null;
  }

  Future<void> _submit(AppCopy copy) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final profile = ref.read(profileControllerProvider).valueOrNull ?? UserProfile.defaults();
    final controller = ref.read(profileControllerProvider.notifier);
    final session = ref.read(sessionControllerProvider.notifier);

    try {
      if (widget.setupMode) {
        await controller.configureLocalLogin(
          displayName: _nameController.text.trim(),
          pin: _pinController.text,
        );
        session.unlock();
      } else {
        final matches = profile.localLogin.verifyPin(_pinController.text);
        if (!matches) {
          setState(() {
            _errorText = copy.choose(
              'That PIN does not match the one saved on this device.',
              'Ese PIN no coincide con el guardado en este dispositivo.',
            );
          });
          return;
        }
        session.unlock();
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
