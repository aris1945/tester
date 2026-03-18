import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/screens/login/login_screen.dart';
import 'package:dompis_app/screens/teknisi/teknisi_dashboard.dart';
import 'package:dompis_app/screens/teknisi/ticket_detail_screen.dart';
import 'package:dompis_app/screens/teknisi/attendance_screen.dart';
import 'package:dompis_app/screens/admin/admin_dashboard.dart';
import 'package:dompis_app/screens/helpdesk/helpdesk_dashboard.dart';
import 'package:dompis_app/screens/superadmin/superadmin_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // Not logged in → go to login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // Logged in and on login page → redirect to role dashboard
      if (isLoggedIn && isLoginRoute) {
        return _getDashboardRoute(authState.role);
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Teknisi routes
      GoRoute(
        path: '/teknisi',
        builder: (context, state) => const TeknisiDashboard(),
      ),
      GoRoute(
        path: '/teknisi/ticket/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/teknisi/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),

      // Helpdesk routes
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) => const HelpdeskDashboard(),
      ),

      // Superadmin routes
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperadminDashboard(),
      ),
    ],
  );
});

String _getDashboardRoute(String? role) {
  switch (role) {
    case 'teknisi':
      return '/teknisi';
    case 'admin':
      return '/admin';
    case 'helpdesk':
      return '/helpdesk';
    case 'superadmin':
      return '/superadmin';
    default:
      return '/login';
  }
}
