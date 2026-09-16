import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import 'error_text.dart';

class VerificationBanner extends ConsumerStatefulWidget {
  const VerificationBanner({super.key});

  @override
  ConsumerState<VerificationBanner> createState() => _VerificationBannerState();
}

class _VerificationBannerState extends ConsumerState<VerificationBanner> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated || auth.user.emailVerified) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondary.withValues(alpha: 0.18),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.verifyEmailBanner, style: theme.textTheme.bodySmall)),
              TextButton(
                onPressed: _sent
                    ? null
                    : () async {
                        try {
                          await ref.read(authRepositoryProvider).resendVerification();
                          if (!context.mounted) return;
                          setState(() => _sent = true);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.verificationSent)));
                        } catch (e) {
                          if (context.mounted) showErrorSnack(context, e);
                        }
                      },
                child: Text(l10n.resendLink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
