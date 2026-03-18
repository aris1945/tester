import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/widgets/app_drawer.dart';
import 'package:dompis_app/widgets/logout_confirm_dialog.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  String? _userName;
  String? _userRole;

  static const _menuItems = [
    DrawerMenuItem(
      label: 'Ticket Management',
      icon: Icons.list_alt_rounded,
      route: '/admin',
    ),
    DrawerMenuItem(
      label: 'Semesta Dompis',
      icon: Icons.inventory_2_rounded,
      route: '/admin/semesta',
    ),
    DrawerMenuItem(
      label: 'Technicians',
      icon: Icons.engineering_rounded,
      route: '/admin/technicians',
    ),
    DrawerMenuItem(
      label: 'Profile',
      icon: Icons.person_rounded,
      route: '/admin/profile',
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
      final response = await apiClient.dio.get(ApiConstants.usersMe);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && mounted) {
        final user = data['data'] as Map<String, dynamic>?;
        setState(() {
          _userName = user?['nama'] as String? ?? user?['username'] as String? ?? 'Admin';
          _userRole = 'Administrator';
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

  String get _currentTitle {
    switch (widget.currentRoute) {
      case '/admin':
        return 'Ticket Management';
      case '/admin/semesta':
        return 'Semesta Dompis';
      case '/admin/technicians':
        return 'Technicians';
      case '/admin/profile':
        return 'Profile';
      default:
        if (widget.currentRoute.startsWith('/admin/technicians/')) {
          return 'Technicians';
        }
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        title: 'Dompis',
        subtitle: 'ADMIN PORTAL',
        menuItems: _menuItems,
        currentRoute: widget.currentRoute,
        userName: _userName,
        userRole: _userRole,
        onLogout: _handleLogout,
        onNavigate: (route) => context.go(route),
      ),
      body: widget.child,
    );
  }
}
