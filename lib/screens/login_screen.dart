import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import 'home_shell.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appConfig = ref.watch(appConfigProvider);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppTheme.brandPrimarySoft.withValues(alpha: 0.22),
                    AppTheme.appBackground,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.paddingOf(context).top -
                      MediaQuery.paddingOf(context).bottom -
                      48,
                  maxWidth: 460,
                ),
                child: Center(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.brandPrimarySoft
                                    .withValues(alpha: 0.24),
                              ),
                            ),
                            child: Image.asset(
                              appConfig.appLogoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.account_balance,
                                size: 52,
                                color: AppTheme.brandPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            appConfig.appTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.brandPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authState.isBusy
                                  ? null
                                  : () async {
                                      await ref.read(authProvider.notifier).login();
                                      final latestAuth = ref.read(authProvider);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (latestAuth.status ==
                                          AuthStatus.authenticated) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const HomeShell(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPrimary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppTheme.brandPrimarySoft,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: authState.isBusy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.brandPrimary,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(Icons.login_rounded, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Iniciar sesion',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (authState.errorMessage != null) ...<Widget>[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.error_outline,
                                    size: 20,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
