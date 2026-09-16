import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Override the API with `--dart-define=MASROOF_API_URL=https://api.example.com`.
abstract final class AppConfig {
  static const _apiOverride = String.fromEnvironment('MASROOF_API_URL');

  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static const appVersion = String.fromEnvironment('MASROOF_VERSION', defaultValue: '1.0.0');
}
