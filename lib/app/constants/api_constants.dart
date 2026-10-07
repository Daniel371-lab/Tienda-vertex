/// Endpoints y claves de configuración externa.
///
/// Los valores sensibles (WhatsApp, Dropi) se leen desde Firestore
/// en la colección `settings` para poder cambiarlos desde el cPanel
/// sin recompilar la app.
abstract final class ApiConstants {
  // Números/URLs por defecto — se sobrescriben desde Firestore `settings`.
  static const String fallbackWhatsappNumber = '595983069263';
  static const String fallbackContactEmail   = 'jplabscreator@gmail.com';

  // Proxy Vercel/Cloudflare (para cuando tengamos la API key de Dropi).
  // Se guardará en Firestore `settings.dropiProxyUrl`.
  static const String fallbackDropiProxyUrl = '';

  // Colecciones de Firestore.
  static const String colCategories = 'categories';
  static const String colProducts   = 'products';
  static const String colOrders     = 'orders';
  static const String colCoupons    = 'coupons';
  static const String colBlacklist  = 'blacklist';
  static const String colSettings   = 'settings';
  static const String colAuditLog   = 'audit_log';

  // Documento único de settings.
  static const String docSettings = 'store';
}