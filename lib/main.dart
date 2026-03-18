import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/router.dart';
import 'package:dompis_app/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: DompisApp()));
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

    return MaterialApp.router(
      title: 'DOMPIS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
