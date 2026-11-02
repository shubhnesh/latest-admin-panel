/// Shared formatting helpers used across the admin panel so every screen
/// renders currency, dates, and relative time the same way.
class Formatters {
  Formatters._();

  /// ₹1,234 style currency (no decimals) — used throughout menu/orders/coupons.
  static String currency(num value, {String symbol = '₹'}) {
    final rounded = value.toStringAsFixed(0);
    final withCommas = rounded.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$symbol$withCommas';
  }

  /// dd/mm/yyyy — used by date pickers across settings/coupons.
  static String date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  /// "Just now" / "5m ago" / "3h ago" / "2d ago" — used by activity + tables.
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
