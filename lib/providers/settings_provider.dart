import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/services/settings_service.dart';

/// Domain model for operating hours of one period (e.g. weekdays / weekends).
class OperatingHours {
  const OperatingHours({
    required this.open,
    required this.close,
    this.isOpen = true,
  });

  final String open; // e.g. "08:00 AM"
  final String close; // e.g. "11:00 PM"
  final bool isOpen;

  OperatingHours copyWith({
    String? open,
    String? close,
    bool? isOpen,
  }) {
    return OperatingHours(
      open: open ?? this.open,
      close: close ?? this.close,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  Map<String, dynamic> toMap() => {
        'open': open,
        'close': close,
        'is_open': isOpen,
      };

  factory OperatingHours.fromMap(
    Map<String, dynamic>? map, {
    required String defaultOpen,
    required String defaultClose,
    bool defaultIsOpen = true,
  }) {
    if (map == null) {
      return OperatingHours(
        open: defaultOpen,
        close: defaultClose,
        isOpen: defaultIsOpen,
      );
    }
    return OperatingHours(
      open: map['open'] as String? ?? defaultOpen,
      close: map['close'] as String? ?? defaultClose,
      isOpen: map['is_open'] as bool? ?? defaultIsOpen,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService() {
    load();
  }

  final SettingsService _service;

  bool isLoading = false;
  String? errorMessage;

  // ── Identity ────────────────────────────────────────────────────────────
  String restaurantName = 'RDX Fast Foods';
  String description = 'Best in city, freshly made every morning.';
  String address = 'Chandigarh';
  String phone = '+91 98765 43210';
  String email = 'contact@rdxrestaurant.com';

  // ── Operational rules ───────────────────────────────────────────────────
  bool autoAcceptOrders = true;
  bool requireManagerApprovalForRefunds = true;
  bool keepPricingConsistent = false;
  bool lateNightDelivery = false;

  // ── Operating hours ─────────────────────────────────────────────────────
  OperatingHours weekdays = const OperatingHours(
    open: '08:00 AM',
    close: '11:00 PM',
    isOpen: true,
  );
  OperatingHours weekends = const OperatingHours(
    open: '10:00 AM',
    close: '02:00 PM',
    isOpen: true,
  );

  bool isLateNightDeliveryTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    final hours = current.weekday >= DateTime.saturday ? weekends : weekdays;
    if (!hours.isOpen) return false;
    final close = _minutes(hours.close);
    final open = _minutes(hours.open);
    final currentMinutes = current.hour * 60 + current.minute;
    if (close > open) return currentMinutes >= close;
    return currentMinutes >= close && currentMinutes < open;
  }

  int _minutes(String value) {
    final normalized = value.trim().toUpperCase();
    final isPm = normalized.endsWith('PM');
    final isAm = normalized.endsWith('AM');
    final clock = isPm || isAm
        ? normalized.substring(0, normalized.length - 2).trim()
        : normalized;
    final parts = clock.split(':');
    var hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  // ── Load ────────────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final d = await _service.load();
      if (d != null) {
        restaurantName = d['restaurant_name'] as String? ?? restaurantName;
        description = d['description'] as String? ?? description;
        address = d['address'] as String? ?? address;
        phone = d['phone'] as String? ?? phone;
        email = d['email'] as String? ?? email;

        autoAcceptOrders = d['auto_accept_orders'] as bool? ?? true;
        requireManagerApprovalForRefunds =
            d['require_manager_approval_for_refunds'] as bool? ?? true;
        keepPricingConsistent = d['keep_pricing_consistent'] as bool? ?? false;
        lateNightDelivery = d['late_night_delivery'] as bool? ?? false;

        weekdays = OperatingHours.fromMap(
          d['weekdays'] as Map<String, dynamic>?,
          defaultOpen: '08:00 AM',
          defaultClose: '11:00 PM',
        );
        weekends = OperatingHours.fromMap(
          d['weekends'] as Map<String, dynamic>?,
          defaultOpen: '10:00 AM',
          defaultClose: '02:00 PM',
        );
      }
    } catch (_) {
      errorMessage = 'Failed to load settings';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Toggles ─────────────────────────────────────────────────────────────
  Future<void> toggleAutoAccept(bool value) async {
    final previous = autoAcceptOrders;
    autoAcceptOrders = value;
    notifyListeners();
    await _persistToggle(
      field: 'auto_accept_orders',
      value: value,
      rollback: () => autoAcceptOrders = previous,
    );
  }

  Future<void> toggleManagerApproval(bool value) async {
    final previous = requireManagerApprovalForRefunds;
    requireManagerApprovalForRefunds = value;
    notifyListeners();
    await _persistToggle(
      field: 'require_manager_approval_for_refunds',
      value: value,
      rollback: () => requireManagerApprovalForRefunds = previous,
    );
  }

  Future<void> toggleKeepPricing(bool value) async {
    final previous = keepPricingConsistent;
    keepPricingConsistent = value;
    notifyListeners();
    await _persistToggle(
      field: 'keep_pricing_consistent',
      value: value,
      rollback: () => keepPricingConsistent = previous,
    );
  }

  Future<void> toggleLateNightDelivery(bool value) async {
    final previous = lateNightDelivery;
    lateNightDelivery = value;
    notifyListeners();
    await _persistToggle(
      field: 'late_night_delivery',
      value: value,
      rollback: () => lateNightDelivery = previous,
    );
  }

  Future<bool> saveOperatingHours({
    required OperatingHours weekdaysHours,
    required OperatingHours weekendsHours,
  }) async {
    try {
      await _service.save({
        'weekdays': weekdaysHours.toMap(),
        'weekends': weekendsHours.toMap(),
      });
      weekdays = weekdaysHours;
      weekends = weekendsHours;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Failed to save operating hours.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistToggle({
    required String field,
    required bool value,
    required void Function() rollback,
  }) async {
    try {
      await _service.updateToggle(field, value);
    } catch (_) {
      rollback();
      errorMessage = 'Failed to save setting.';
      notifyListeners();
    }
  }

  // ── Full save (identity + hours) ────────────────────────────────────────
  Future<bool> save({
    required String name,
    required String desc,
    required String addr,
    required String ph,
    required String em,
    OperatingHours? weekdaysHours,
    OperatingHours? weekendsHours,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final newWeekdays = weekdaysHours ?? weekdays;
    final newWeekends = weekendsHours ?? weekends;

    try {
      await _service.save({
        'restaurant_name': name,
        'description': desc,
        'address': addr,
        'phone': ph,
        'email': em,
        'auto_accept_orders': autoAcceptOrders,
        'require_manager_approval_for_refunds':
            requireManagerApprovalForRefunds,
        'keep_pricing_consistent': keepPricingConsistent,
        'late_night_delivery': lateNightDelivery,
        'weekdays': newWeekdays.toMap(),
        'weekends': newWeekends.toMap(),
      });

      restaurantName = name;
      description = desc;
      address = addr;
      phone = ph;
      email = em;
      weekdays = newWeekdays;
      weekends = newWeekends;

      isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Failed to save settings.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [SettingsProvider].
final settingsProvider = ChangeNotifierProvider<SettingsProvider>(
  (ref) => SettingsProvider(),
);
