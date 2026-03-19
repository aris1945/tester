import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/router.dart';
import 'package:dompis_app/providers/auth_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dompis_app/providers/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const DompisApp(),
  ));
}

class DompisApp extends ConsumerStatefulWidget {
  const DompisApp({super.key});

  @override
  ConsumerState<DompisApp> createState() => _DompisAppState();
}

class _DompisAppState extends ConsumerState<DompisApp> {
  @override
  void initState() {
    super.initState();
    // Check auth state on startup
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final currentThemeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'DOMPIS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode,
      routerConfig: router,
    );
  }
}
