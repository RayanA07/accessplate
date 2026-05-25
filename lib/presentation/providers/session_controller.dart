import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionState {
  const SessionState({this.unlocked = false});

  final bool unlocked;

  SessionState copyWith({bool? unlocked}) {
    return SessionState(unlocked: unlocked ?? this.unlocked);
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  void unlock() {
    state = state.copyWith(unlocked: true);
  }

  void lock() {
    state = state.copyWith(unlocked: false);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
