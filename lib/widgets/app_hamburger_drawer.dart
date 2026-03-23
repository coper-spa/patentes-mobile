import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../screens/calendar_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/route_map_screen.dart';

enum AppSection { route, calendar, summary }

class AppHamburgerDrawer extends ConsumerWidget {
  const AppHamburgerDrawer({super.key, required this.current});

  final AppSection current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appConfig = ref.watch(appConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset((1 - value) * -20, 0),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            appConfig.appLogoAsset,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance,
                              size: 40,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authState.profile?.fullName ?? 'Inspector',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.profile?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DrawerOption(
              delayMs: 40,
              icon: Icons.map_outlined,
              label: 'Mapa y ruta',
              selected: current == AppSection.route,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                if (current == AppSection.route) {
                  return;
                }
                Navigator.of(context).pushReplacement(_buildTransitionRoute(
                  const RouteMapScreen(day: null),
                ));
              },
            ),
            _DrawerOption(
              delayMs: 90,
              icon: Icons.calendar_month_outlined,
              label: 'Calendario',
              selected: current == AppSection.calendar,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                if (current == AppSection.calendar) {
                  return;
                }
                Navigator.of(context).pushReplacement(_buildTransitionRoute(
                  const CalendarScreen(),
                ));
              },
            ),
            _DrawerOption(
              delayMs: 140,
              icon: Icons.dashboard_outlined,
              label: 'Resumen',
              selected: current == AppSection.summary,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                if (current == AppSection.summary) {
                  return;
                }
                Navigator.of(context).pushReplacement(_buildTransitionRoute(
                  const DashboardScreen(),
                ));
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerOption(
              delayMs: 190,
              icon: Icons.logout_rounded,
              label: 'Cerrar sesion',
              selected: false,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final rootNavigator = Navigator.of(context, rootNavigator: true);
                Navigator.of(context).pop();
                try {
                  await ref.read(authProvider.notifier).logout();
                } catch (_) {
                  // Even if logout cleanup fails, return to login screen.
                }
                if (!rootNavigator.mounted) {
                  return;
                }
                rootNavigator.pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  PageRoute<void> _buildTransitionRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _DrawerOption extends StatelessWidget {
  const _DrawerOption({
    required this.delayMs,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int delayMs;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * -14, 0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: ListTile(
          leading: Icon(
            icon,
            color:
                selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          selected: selected,
          selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }
}
