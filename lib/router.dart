import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/screens/login/login_screen.dart';

// Teknisi
import 'package:dompis_app/screens/teknisi/teknisi_shell.dart';
import 'package:dompis_app/screens/teknisi/ticket_detail_screen.dart';

// Admin
import 'package:dompis_app/screens/admin/admin_shell.dart';
import 'package:dompis_app/screens/admin/admin_dashboard.dart';
import 'package:dompis_app/screens/admin/admin_semesta_screen.dart';
import 'package:dompis_app/screens/admin/admin_technicians_screen.dart';
import 'package:dompis_app/screens/admin/admin_tech_subpages.dart';

// Helpdesk
import 'package:dompis_app/screens/helpdesk/helpdesk_shell.dart';
import 'package:dompis_app/screens/helpdesk/helpdesk_dashboard.dart';

// Superadmin
import 'package:dompis_app/screens/superadmin/superadmin_shell.dart';
import 'package:dompis_app/screens/superadmin/superadmin_dashboard.dart';

// Shared
import 'package:dompis_app/widgets/profile_page.dart';

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

      // ─── Teknisi ───────────────────────────────────────────────
      GoRoute(
        path: '/teknisi',
        builder: (context, state) => const TeknisiShell(),
      ),
      GoRoute(
        path: '/teknisi/ticket/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TicketDetailScreen(ticketId: id);
        },
      ),

      // ─── Admin ─────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin',
          child: const AdminDashboard(),
        ),
      ),
      GoRoute(
        path: '/admin/semesta',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/semesta',
          child: const AdminSemestaScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/technicians',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/technicians',
          child: const AdminTechniciansScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/technicians/attendance',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/technicians',
          child: const AdminTechAttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/technicians/performance',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/technicians',
          child: const AdminTechPerformanceScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/technicians/manhours',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/technicians',
          child: const AdminTechManhoursScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => AdminShell(
          currentRoute: '/admin/profile',
          child: const ProfilePage(),
        ),
      ),

      // ─── Helpdesk ──────────────────────────────────────────────
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) => HelpdeskShell(
          currentRoute: '/helpdesk',
          child: const HelpdeskDashboard(),
        ),
      ),
      GoRoute(
        path: '/helpdesk/profile',
        builder: (context, state) => HelpdeskShell(
          currentRoute: '/helpdesk/profile',
          child: const ProfilePage(),
        ),
      ),

      // ─── Superadmin ────────────────────────────────────────────
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => SuperadminShell(
          currentRoute: '/superadmin',
          child: const SuperadminDashboard(),
        ),
      ),
      GoRoute(
        path: '/superadmin/profile',
        builder: (context, state) => SuperadminShell(
          currentRoute: '/superadmin/profile',
          child: const ProfilePage(),
        ),
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
