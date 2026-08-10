import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0, 0.6)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Give the animation time to play + Supabase to restore session
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Wait for auth to finish loading session
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return auth.isLoading;
    });

    if (!mounted) return;

    if (auth.isLoggedIn) {
      final user = auth.currentUser!;
      // Pre-load all data
      await Future.wait([
        context.read<ProductProvider>().loadData(user.id),
        context.read<ChatProvider>().loadConversations(user.id),
      ]);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user.role.name == 'seller'
            ? AppRoutes.sellerDashboard
            : AppRoutes.buyerDashboard,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.splashGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_work_rounded,
                          size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text('HostelHub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 8),
                    Text('Buy & Sell Within Your Hostel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 32, height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white.withValues(alpha: 0.7),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
