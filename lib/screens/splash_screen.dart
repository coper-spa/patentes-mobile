import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../models/app_update_info.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  AppUpdateInfo? _appUpdateInfo;
  bool _isVersionCheckDone = false;
  bool _optionalPromptHandled = false;
  bool _isShowingOptionalPrompt = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.microtask(_startBootstrap);
  }

  Future<void> _startBootstrap() async {
    ref.read(authProvider.notifier).restoreSession();
    await _runVersionCheck();
  }

  Future<void> _runVersionCheck() async {
    final service = ref.read(appUpdateServiceProvider);
    final info = await service.checkForUpdate();

    if (!mounted) {
      return;
    }

    setState(() {
      _appUpdateInfo = info;
      _isVersionCheckDone = true;
      if (info.updateType != AppUpdateType.optional) {
        _optionalPromptHandled = true;
      }
    });
  }

  Future<void> _showOptionalUpdateDialog(AppUpdateInfo info) async {
    if (_isShowingOptionalPrompt) {
      return;
    }

    _isShowingOptionalPrompt = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(info.title ?? 'Actualizacion disponible'),
          content: Text(
            info.message ??
                'Existe una nueva version disponible. Puedes actualizar ahora o mas tarde.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Mas tarde'),
            ),
            FilledButton(
              onPressed: () async {
                final targetUrl = info.targetUrl;
                if (targetUrl != null) {
                  final uri = Uri.tryParse(targetUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _optionalPromptHandled = true;
      _isShowingOptionalPrompt = false;
    });
  }

  Future<void> _openRequiredUpdate(AppUpdateInfo info) async {
    final targetUrl = info.targetUrl;
    if (targetUrl == null) {
      return;
    }

    final uri = Uri.tryParse(targetUrl);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildLoading(AppConfig appConfig) {
    return Scaffold(
      body: Container(
        color: AppTheme.appBackground,
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.brandPrimarySoft.withValues(alpha: 0.2),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    appConfig.appLogoAsset,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_balance,
                      size: 64,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredUpdateScreen(AppUpdateInfo info) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.system_update_rounded,
                  size: 64,
                  color: AppTheme.brandPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  info.title ?? 'Actualizacion obligatoria',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  info.message ??
                      'Debes actualizar la app para continuar usando el servicio.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: info.targetUrl == null
                      ? null
                      : () => _openRequiredUpdate(info),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Actualizar ahora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final appConfig = ref.watch(appConfigProvider);
    final updateInfo = _appUpdateInfo;

    if (!_isVersionCheckDone || updateInfo == null) {
      return _buildLoading(appConfig);
    }

    if (updateInfo.updateType == AppUpdateType.required) {
      return _buildRequiredUpdateScreen(updateInfo);
    }

    if (updateInfo.updateType == AppUpdateType.optional &&
        !_optionalPromptHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOptionalUpdateDialog(updateInfo);
      });
      return _buildLoading(appConfig);
    }

    if (state.status == AuthStatus.authenticated) {
      return const HomeShell();
    }

    if (state.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    return _buildLoading(appConfig);
  }
}
