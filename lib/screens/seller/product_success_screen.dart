import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class ProductSuccessScreen extends StatefulWidget {
  final dynamic product;
  const ProductSuccessScreen({super.key, this.product});

  @override
  State<ProductSuccessScreen> createState() => _ProductSuccessScreenState();
}

class _ProductSuccessScreenState extends State<ProductSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productTitle = widget.product?.title ?? 'Your Product';
    final productPrice = widget.product?.price?.toStringAsFixed(0) ?? '0';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated check icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const Text('Product Listed!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 10),
                      Text('"$productTitle" has been posted\nsuccessfully at ₹$productPrice.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary,
                              fontSize: 15, height: 1.6)),
                      const SizedBox(height: 40),
                      // Confetti-style bubbles
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SuccessBadge(icon: Icons.visibility_outlined, label: 'Now Visible'),
                          _SuccessBadge(icon: Icons.chat_bubble_outline, label: 'Buyers Can Chat'),
                          _SuccessBadge(icon: Icons.notifications_outlined, label: 'Get Notified'),
                        ],
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.myProducts, (r) => false),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('View My Products',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.sellItem, (r) => false),
                        icon: const Icon(Icons.add),
                        label: const Text('Sell Another Item',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.sellerDashboard, (r) => false),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SuccessBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.success)),
        ],
      ),
    );
  }
}
