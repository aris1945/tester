import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/widgets/app_drawer.dart';
import 'package:dompis_app/widgets/logout_confirm_dialog.dart';

class HelpdeskShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const HelpdeskShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<HelpdeskShell> createState() => _HelpdeskShellState();
}

class _HelpdeskShellState extends ConsumerState<HelpdeskShell> {
  String? _userName;

  static const _menuItems = [
    DrawerMenuItem(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: '/helpdesk',
    ),
    DrawerMenuItem(
      label: 'Profile',
      icon: Icons.person_rounded,
      route: '/helpdesk/profile',
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
          _userName = user?['nama'] as String? ?? user?['username'] as String? ?? 'Helpdesk';
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
        title: Text(widget.currentRoute == '/helpdesk/profile' ? 'Profile' : 'Helpdesk Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        title: 'Dompis',
        subtitle: 'HELPDESK',
        menuItems: _menuItems,
        currentRoute: widget.currentRoute,
        userName: _userName,
        userRole: 'Helpdesk',
        onLogout: _handleLogout,
        onNavigate: (route) => context.go(route),
      ),
      body: widget.child,
    );
  }
}
