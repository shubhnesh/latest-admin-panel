/// Keys used with SharedPreferences / local storage for the admin app.
/// Centralized here so a typo doesn't silently break persistence.
class StorageKeys {
  StorageKeys._();

  static const String adminToken = 'admin_token';
  static const String adminId = 'admin_id';
  static const String restaurantId = 'restaurant_id';
  static const String lastSelectedRoute = 'last_selected_route';
}
