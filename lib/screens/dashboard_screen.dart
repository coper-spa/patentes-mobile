import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/app_hamburger_drawer.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/next_inspection_card.dart';
import 'inspection_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppHamburgerDrawer(current: AppSection.summary),
      appBar: AppBar(
        title: const Text('Resumen'),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dashboardState.when(
          data: (summary) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 12),
                    child: child,
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: <Widget>[
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hola,',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.profile?.fullName ?? 'Inspector',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.profile?.email ?? '',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DashboardSummaryCard(summary: summary),
                  const SizedBox(height: 16),
                  NextInspectionCard(
                    nextInspection: summary.nextInspection,
                    onOpen: () {
                      final next = summary.nextInspection;
                      if (next == null) return;
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              InspectionDetailScreen(inspectionId: next.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingState(),
          error: (error, stack) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
      ),
    );
  }
}
