import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/masroof_logo.dart';
import '../features/accounts/presentation/account_detail_screen.dart';
import '../features/accounts/presentation/account_form_screen.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/categories/presentation/category_form_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'app_shell.dart';

const _publicRoutes = {'/login', '/register', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = refresh.value;
      final location = state.matchedLocation;
      if (auth is AuthLoading) return location == '/splash' ? null : '/splash';
      if (auth is Unauthenticated) return _publicRoutes.contains(location) ? null : '/login';
      if (_publicRoutes.contains(location) || location == '/splash') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/transactions/new',
        builder: (_, state) => TransactionFormScreen(
          initialType: state.uri.queryParameters['type'] ?? 'expense',
          initialAccountId: state.uri.queryParameters['account'],
        ),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (_, state) => TransactionFormScreen(transactionId: state.pathParameters['id']),
      ),
      GoRoute(path: '/accounts/new', builder: (_, _) => const AccountFormScreen()),
      GoRoute(
        path: '/accounts/:id',
        builder: (_, state) => AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (_, state) => AccountFormScreen(accountId: state.pathParameters['id']),
      ),
      GoRoute(path: '/settings/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(
        path: '/settings/categories/new',
        builder: (_, state) => CategoryFormScreen(initialType: state.uri.queryParameters['type'] ?? 'expense'),
      ),
      GoRoute(
        path: '/settings/categories/:id/edit',
        builder: (_, state) => CategoryFormScreen(categoryId: state.pathParameters['id']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/transactions', builder: (_, _) => const TransactionsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/accounts', builder: (_, _) => const AccountsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),
    ],
  );
});

/// Shown for the brief moment the stored session is being restored; matches
/// the native launch screen so the handoff is seamless.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF07463D),
    body: Center(child: MasroofLogo(size: 112, showWordmark: true, wordmarkColor: Colors.white, onDark: true)),
  );
}
