import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/widgets/app_drawer.dart';
import 'package:dompis_app/widgets/logout_confirm_dialog.dart';

class SuperadminShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const SuperadminShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<SuperadminShell> createState() => _SuperadminShellState();
}

class _SuperadminShellState extends ConsumerState<SuperadminShell> {
  String? _userName;

  static const _menuItems = [
    DrawerMenuItem(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: '/superadmin',
    ),
    DrawerMenuItem(
      label: 'Profile',
      icon: Icons.person_rounded,
      route: '/superadmin/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(ApiConstants.usersMeSa);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && mounted) {
        final user = data['data'] as Map<String, dynamic>?;
        setState(() {
          _userName = user?['nama'] as String? ?? user?['username'] as String? ?? 'Superadmin';
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentRoute == '/superadmin/profile' ? 'Profile' : 'Superadmin Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        title: 'Dompis',
        subtitle: 'SUPERADMIN',
        menuItems: _menuItems,
        currentRoute: widget.currentRoute,
        userName: _userName,
        userRole: 'Superadmin',
        onLogout: _handleLogout,
        onNavigate: (route) => context.go(route),
      ),
      body: widget.child,
    );
  }
}
