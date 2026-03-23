import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Permite ejecutar via --dart-define cuando no existe archivo .env.
  }

  runApp(const ProviderScope(child: InspectoresApp()));
}

class InspectoresApp extends ConsumerWidget {
  const InspectoresApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: config.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
