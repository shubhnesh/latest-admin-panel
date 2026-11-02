import 'package:flutter/material.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/order/order_details_screen.dart';
import '../../screens/menu/create_menu_screen.dart';
import '../../screens/coupons/create_coupon_screen.dart';
import '../../screens/settings/restaurant_profile_screen.dart';

/// Simple centralized named-route table. No routing package needed for an
/// app this size — Navigator + named routes keeps it easy to reason about.
/// The persistent sidebar sections (dashboard/orders/menu/etc.) are handled
/// inside MainScreen itself via IndexedStack, not through this router —
/// this table is only for screens that get pushed on top (detail/forms).
class AppRoutes {
  AppRoutes._();

  static const String main = '/main';
  static const String orderDetail = '/order-detail';
  static const String editMenuItem = '/edit-menu-item';
  static const String createCoupon = '/create-coupon';
  static const String restaurantProfile = '/restaurant-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case orderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(orderId: orderId));
      case editMenuItem:
        final itemId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) => CreateMenuScreen(itemId: itemId));
      case createCoupon:
        return MaterialPageRoute(builder: (_) => const CreateCouponScreen());
      case restaurantProfile:
        return MaterialPageRoute(
          builder: (_) => const RestaurantProfileScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
