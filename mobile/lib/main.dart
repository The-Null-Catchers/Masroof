import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'features/auth/application/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);

  // Push queued offline changes as soon as connectivity returns.
  Connectivity().onConnectivityChanged.listen((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online && container.read(authControllerProvider) is Authenticated) {
      unawaited(container.read(syncEngineProvider).sync());
    }
  });

  runApp(UncontrolledProviderScope(container: container, child: const MasroofApp()));
}
