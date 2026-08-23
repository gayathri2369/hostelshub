import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/review_provider.dart';
import 'utils/app_theme.dart';
import 'utils/supabase_config.dart';
import 'services/gemini_vision_service.dart';

// Auth screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Seller screens
import 'screens/seller/seller_dashboard.dart';
import 'screens/seller/sell_item_flow.dart';
import 'screens/seller/my_products_screen.dart';
import 'screens/seller/product_success_screen.dart';

// Buyer screens
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/buyer/product_detail_screen.dart';
import 'screens/buyer/wishlist_screen.dart';

// Common screens
import 'screens/common/chat_screen.dart';
import 'screens/common/conversations_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/common/settings_screen.dart';
import 'screens/common/donate_screen.dart';
import 'widgets/back_navigation_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url:            SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // List available Gemini models on startup (for debugging)
  if (GeminiVisionService.isConfigured) {
    GeminiVisionService.listAvailableModels();
  }

  runApp(const HostelHubApp());
}

class HostelHubApp extends StatelessWidget {
  const HostelHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'HostelHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class AppRoutes {
  static const String splash          = '/';
  static const String login           = '/login';
  static const String register        = '/register';
  static const String sellerDashboard = '/seller/dashboard';
  static const String buyerDashboard  = '/buyer/dashboard';
  static const String sellItem        = '/seller/sell-item';
  static const String myProducts      = '/seller/my-products';
  static const String productSuccess  = '/seller/product-success';
  static const String productDetail   = '/buyer/product-detail';
  static const String wishlist        = '/buyer/wishlist';
  static const String chat            = '/chat';
  static const String conversations   = '/conversations';
  static const String profile         = '/profile';
  static const String settings        = '/settings';
  static const String donate          = '/donate';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _fade(const SplashScreen());
      case login:
        return _slide(const LoginScreen());
      case register:
        return _slide(const RegisterScreen());
      case sellerDashboard:
        return _fade(const SellerDashboard());
      case buyerDashboard:
        return _fade(const BuyerDashboard());
      case sellItem:
        return _slide(_guarded(const SellItemFlow()));
      case myProducts:
        return _slide(_guarded(const MyProductsScreen()));
      case productSuccess:
        return _fade(_guarded(ProductSuccessScreen(product: routeSettings.arguments)));
      case productDetail:
        return _slide(_guarded(
            ProductDetailScreen(productId: routeSettings.arguments as String)));
      case wishlist:
        return _slide(_guarded(const WishlistScreen()));
      case chat:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return _slide(_guarded(ChatScreen(
          conversationId:  args['conversationId'],
          otherPersonName: args['otherPersonName'],
          productTitle:    args['productTitle'],
        )));
      case conversations:
        return _slide(_guarded(const ConversationsScreen()));
      case profile:
        return _slide(_guarded(const ProfileScreen()));
      case settings:
        return _slide(_guarded(const SettingsScreen()));
      case donate:
        return _slide(_guarded(const DonateScreen()));
      default:
        return _fade(const SplashScreen());
    }
  }

  /// Wraps authenticated screens with back navigation guard
  static Widget _guarded(Widget child) => BackNavigationGuard(child: child);

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  static PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
