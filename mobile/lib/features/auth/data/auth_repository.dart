import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository({required this._api, required this._tokens, required this._db});

  static const _userKey = 'auth.user';
  static const deviceName = 'Masroof mobile';

  final ApiClient _api;
  final TokenStorage _tokens;
  final AppDatabase _db;

  /// Restores a session from secure storage without network access.
  Future<User?> restore() async {
    final token = await _tokens.read();
    final cached = await _db.readValue(_userKey);
    if (token == null || cached == null) return null;
    return User.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  Future<User> login({required String email, required String password}) async {
    final response = await _api.post('/auth/login', {'email': email, 'password': password, 'device_name': deviceName});
    return _startSession(response);
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String locale,
    required String currency,
  }) async {
    final response = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'locale': locale,
      'currency': currency,
      'device_name': deviceName,
    });
    return _startSession(response);
  }

  Future<void> forgotPassword(String email) => _api.post('/auth/forgot-password', {'email': email});

  Future<User> refreshProfile() async {
    final response = await _api.get('/me');
    return _cache(User.fromJson(response['data'] as Map<String, dynamic>));
  }

  /// Updates profile preferences and financial settings (PATCH /settings).
  Future<User> updateSettings(Map<String, Object?> changes) async {
    final response = await _api.patch('/settings', changes);
    return _cache(User.fromJson(response['data'] as Map<String, dynamic>));
  }

  /// Saves onboarding answers (all optional) and marks onboarding complete.
  Future<User> completeOnboarding(Map<String, Object?> answers) async {
    final response = await _api.post('/onboarding', answers);
    return _cache(User.fromJson(response['data'] as Map<String, dynamic>));
  }

  Future<void> resendVerification() => _api.post('/auth/email/verification-notification', const {});

  Future<void> changePassword({required String current, required String next}) =>
      _api.put('/me/password', {'current_password': current, 'password': next, 'password_confirmation': next});

  Future<void> deleteAccount(String password) async {
    await _api.delete('/me', {'password': password});
    await clearLocalSession();
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Signing out locally must succeed even when offline.
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokens.clear();
    await _db.clearAll();
  }

  Future<User> _startSession(Map<String, dynamic> response) async {
    // Never mix cached data from a previous account.
    await _db.clearAll();
    await _tokens.write(response['token'] as String);
    return _cache(User.fromJson(response['user'] as Map<String, dynamic>));
  }

  Future<User> _cache(User user) async {
    await _db.writeValue(_userKey, jsonEncode(user.toJson()));
    return user;
  }
}
