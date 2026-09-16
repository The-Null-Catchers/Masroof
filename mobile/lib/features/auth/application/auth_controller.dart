import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../domain/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  final bool sessionExpired;
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthLoading();
  }

  Future<void> _restore() async {
    final user = await ref.read(authRepositoryProvider).restore();
    if (user == null) {
      state = const Unauthenticated();
      return;
    }
    _signedIn(user);
    // Refresh the profile in the background; offline is fine.
    unawaited(
      ref
          .read(authRepositoryProvider)
          .refreshProfile()
          .then((fresh) {
            if (state is Authenticated) state = Authenticated(fresh);
          })
          .catchError((Object _) {}),
    );
  }

  Future<void> login(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).login(email: email.trim(), password: password);
    _signedIn(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String locale,
    required String currency,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(name: name.trim(), email: email.trim(), password: password, locale: locale, currency: currency);
    _signedIn(user);
  }

  Future<void> updateProfile(Map<String, Object?> changes) async {
    final user = await ref.read(authRepositoryProvider).updateProfile(changes);
    state = Authenticated(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Unauthenticated();
  }

  Future<void> deleteAccount(String password) async {
    await ref.read(authRepositoryProvider).deleteAccount(password);
    state = const Unauthenticated();
  }

  /// Called by the API client when the server rejects the token.
  void onSessionExpired() {
    if (state is! Authenticated) return;
    state = const Unauthenticated(sessionExpired: true);
    unawaited(ref.read(authRepositoryProvider).clearLocalSession());
  }

  void _signedIn(User user) {
    state = Authenticated(user);
    unawaited(
      ref.read(syncEngineProvider).sync().catchError((Object e) {
        if (e is ApiException && e.kind == ApiErrorKind.unauthorized) onSessionExpired();
        return ref.read(syncEngineProvider).current;
      }),
    );
  }
}
