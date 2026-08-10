import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../main.dart';

/// Prevents app exit on back gesture - redirects to dashboard instead
class BackNavigationGuard extends StatelessWidget {
  final Widget child;
  final bool isDashboard;

  const BackNavigationGuard({
    super.key,
    required this.child,
    this.isDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackNavigation(context);
      },
      child: child,
    );
  }

  void _handleBackNavigation(BuildContext context) {
    final auth = context.read<AuthProvider>();
    
    // If user is not logged in, do nothing (shouldn't happen but safety check)
    if (auth.currentUser == null) return;

    // If already on dashboard, do nothing (prevent exit)
    if (isDashboard) return;

    // Navigate to appropriate dashboard based on user role
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final targetRoute = auth.currentUser?.role == UserRole.seller
        ? AppRoutes.sellerDashboard
        : AppRoutes.buyerDashboard;

    // If not already on target dashboard, go there
    if (currentRoute != targetRoute) {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }
}
